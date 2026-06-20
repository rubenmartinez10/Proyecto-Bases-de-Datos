-- 1° Trigger

-- Función para trigger de verificación de alergia

CREATE OR REPLACE FUNCTION fn_verificar_alergia_medicamento()
RETURNS TRIGGER AS $$
DECLARE
    v_id_mascota BIGINT;
    v_existe_alergia INT;
BEGIN
    -- 1. Encontrar el id_mascota a partir del id_tratamiento que se está insertando
    SELECT c.id_mascota INTO v_id_mascota
    FROM tratamiento t
    JOIN diagnostico d ON t.id_diagnostico = d.id_diagnostico
    JOIN consulta c ON d.id_consulta = c.id_consulta
    WHERE t.id_tratamiento = NEW.id_tratamiento;

    -- 2. Contar si la mascota tiene registrada una alergia a ESTE medicamento específico 
    SELECT COUNT(*) INTO v_existe_alergia
    FROM mascota_alergia
    WHERE id_mascota = v_id_mascota 
      AND id_medicamento = NEW.id_medicamento;

    -- 3. Si el conteo es mayor a 0, significa que sí es alérgica
    IF v_existe_alergia > 0 THEN
        RAISE EXCEPTION 'Error: No se puede recetar este medicamento. La mascota es alérgica a él.';
    END IF;

    -- Si no es alérgica, que la inserción continúe normalmente
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- Trigger
-- ============================================================

CREATE OR REPLACE TRIGGER trg_verificar_alergia_medicamento
BEFORE INSERT OR UPDATE ON tratamiento_medicamento
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_alergia_medicamento();


-------------------------------------------------------------------------------------

-- 2° Trigger

-- Función para trigger de automatización de precios de medicamentos

CREATE OR REPLACE FUNCTION fn_automatizar_precio_medicamento()
RETURNS TRIGGER AS $$
DECLARE
    v_precio_actual NUMERIC(7,2);
BEGIN
    -- Si es una inserción nueva,se toma el precio real del medicamento
    IF TG_OP = 'INSERT' THEN
        SELECT costo_unitario INTO v_precio_actual
        FROM medicamento
        WHERE id_medicamento = NEW.id_medicamento;

        -- Le asignamos el precio real al registro que se está guardando
        NEW.precio_historico := v_precio_actual;
    
    -- Si intentan hacer un UPDATE, se bloquean los cambios
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.precio_historico <> OLD.precio_historico THEN
            RAISE EXCEPTION 'Error: El precio histórico de una receta no puede ser modificado.';
        END IF;
        
        IF NEW.id_medicamento <> OLD.id_medicamento THEN
            RAISE EXCEPTION 'Error: No puedes cambiar el medicamento de un tratamiento existente. Elimínalo y crea uno nuevo.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger

CREATE OR REPLACE TRIGGER trg_automatizar_precio_medicamento
BEFORE INSERT OR UPDATE ON tratamiento_medicamento
FOR EACH ROW
EXECUTE FUNCTION fn_automatizar_precio_medicamento();


-------------------------------------------------------------------------------------
-- 3° Trigger

-- Función para verificar si el veterinario ya tiene una consulta programada

CREATE OR REPLACE FUNCTION fn_evitar_choque_consultas()
RETURNS TRIGGER AS $$
DECLARE
    v_ya_ocupado INT;
BEGIN
    -- Contar si el veterinario ya tiene una consulta ese mismo día a esa misma hora
   	SELECT COUNT(*) INTO v_ya_ocupado
	FROM consulta
	WHERE id_veterinario = NEW.id_veterinario
  	AND fecha_hora_inicio = NEW.fecha_hora_inicio;

    -- Si ya tiene una, bloqueamos el registro
    IF v_ya_ocupado > 0 THEN
        RAISE EXCEPTION 'Error: El veterinario ya tiene otra consulta asignada para la fecha % a las %.', NEW.fecha, NEW.hora_consulta;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger

CREATE OR REPLACE TRIGGER trg_evitar_choque_consultas
BEFORE INSERT ON consulta
FOR EACH ROW
EXECUTE FUNCTION fn_evitar_choque_consultas();