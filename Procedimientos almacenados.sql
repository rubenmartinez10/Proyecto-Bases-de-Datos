-- ============================================================
-- 1. sp_generar_historial
-- Genera el historial clínico completo de una mascota dado su ID
-- ============================================================
create or replace procedure sp_generar_historial(p_id_mascota bigint)
language plpgsql
as $$
declare
    -- datos generales de la mascota
    v_nombre_mascota    varchar(255);
    v_especie           varchar(255);
    v_raza              varchar(255);
    v_propietario       varchar(255);

    -- variables para recorrer los resultados de cada select dentro de los loops
    r_consulta          record;
    r_diagnostico       record;
    r_tratamiento       record;
    r_medicamento       record;
    r_procedimiento     record;
    r_alergia           record;
begin
    -- verificar que la mascota existe y traer sus datos generales
    select
        m.nombre,
        e.nombre,
        r.nombre,
        p.nombre || ' ' || p.apellido
    into
        v_nombre_mascota,
        v_especie,
        v_raza,
        v_propietario
    from mascota m
    join raza r          on r.id_raza        = m.id_raza
    join especie e       on e.id_especie     = r.id_especie
    join propietario p   on p.id_propietario = m.id_propietario
    where m.id_mascota = p_id_mascota;

    if not found then
        raise exception 'No existe una mascota con id %', p_id_mascota;
    end if;

    -- encabezado del historial
    raise notice '==================================================';
    raise notice 'Historial clinico';
    raise notice 'Mascota    : % (ID: %)', v_nombre_mascota, p_id_mascota;
    raise notice 'Especie    : % - %', v_especie, v_raza;
    raise notice 'Propietario: %', v_propietario;
    raise notice '==================================================';

    -- alergias registradas
    raise notice '';
    raise notice '-- Alergias registradas --';

    for r_alergia in
        select
            med.nombre      as medicamento,
            ma.severidad,
            ma.reaccion,
            ma.fecha_deteccion
        from mascota_alergia ma
        join medicamento med on med.id_medicamento = ma.id_medicamento
        where ma.id_mascota = p_id_mascota
        order by ma.fecha_deteccion
    loop
        raise notice '  [%] % - % (detectada: %)',
            r_alergia.severidad,
            r_alergia.medicamento,
            r_alergia.reaccion,
            r_alergia.fecha_deteccion;
    end loop;

    -- consultas de la mascota
    raise notice '';
    raise notice '-- Consultas --';

    for r_consulta in
        select
            c.id_consulta,
            c.fecha_hora_inicio,
            c.motivo,
            c.estado,
            c.descripcion,
            c.costo_consulta,
            v.nombre || ' ' || v.apellidos as veterinario,
            esp.nombre                     as especialidad
        from consulta c
        join veterinario v    on v.id_veterinario   = c.id_veterinario
        join especialidad esp on esp.id_especialidad = v.id_especialidad
        where c.id_mascota = p_id_mascota
        order by c.fecha_hora_inicio
    loop
        raise notice '';
        raise notice '  Consulta #% | % | Estado: %',
            r_consulta.id_consulta,
            r_consulta.fecha_hora_inicio,
            r_consulta.estado;
        raise notice '  Motivo     : %', r_consulta.motivo;
        raise notice '  Veterinario: % (%)', r_consulta.veterinario, r_consulta.especialidad;

        -- si la descripcion es null, mostramos n/a en su lugar
        if r_consulta.descripcion is null then
            raise notice '  Descripcion: N/A';
        else
            raise notice '  Descripcion: %', r_consulta.descripcion;
        end if;

        raise notice '  Costo      : $%', r_consulta.costo_consulta;

        -- diagnosticos de esta consulta
        for r_diagnostico in
            select
                d.id_diagnostico,
                d.detalle,
                d.gravedad,
                d.fecha_emision
            from diagnostico d
            where d.id_consulta = r_consulta.id_consulta
        loop
            raise notice '    > Diagnostico #% [%] (emitido: %): %',
                r_diagnostico.id_diagnostico,
                r_diagnostico.gravedad,
                r_diagnostico.fecha_emision,
                r_diagnostico.detalle;

            -- procedimientos asociados al diagnostico
            for r_procedimiento in
                select
                    pr.nombre,
                    pd.fecha_programada,
                    pd.precio_historico,
                    pd.observaciones
                from procedimiento_diagnostico pd
                join procedimiento pr on pr.id_procedimiento = pd.id_procedimiento
                where pd.id_diagnostico = r_diagnostico.id_diagnostico
            loop
                raise notice '       Procedimiento: % | Fecha: % | $%',
                    r_procedimiento.nombre,
                    r_procedimiento.fecha_programada,
                    r_procedimiento.precio_historico;

                if r_procedimiento.observaciones is not null then
                    raise notice '       Observaciones: %', r_procedimiento.observaciones;
                end if;
            end loop;

            -- tratamientos asociados al diagnostico
            for r_tratamiento in
                select
                    t.id_tratamiento,
                    t.detalle,
                    t.duracion,
                    t.fecha_inicio
                from tratamiento t
                where t.id_diagnostico = r_diagnostico.id_diagnostico
            loop
                raise notice '       Tratamiento #%: % | Duracion: % | Inicio: %',
                    r_tratamiento.id_tratamiento,
                    r_tratamiento.detalle,
                    r_tratamiento.duracion,
                    r_tratamiento.fecha_inicio;

                -- medicamentos prescritos en el tratamiento
                for r_medicamento in
                    select
                        med.nombre,
                        tm.dosis,
                        tm.frecuencia,
                        tm.cantidad_prescrita,
                        tm.precio_historico
                    from tratamiento_medicamento tm
                    join medicamento med on med.id_medicamento = tm.id_medicamento
                    where tm.id_tratamiento = r_tratamiento.id_tratamiento
                loop
                    raise notice '         Medicamento: % | Dosis: % % | Cant: % | $%',
                        r_medicamento.nombre,
                        r_medicamento.dosis,
                        r_medicamento.frecuencia,
                        r_medicamento.cantidad_prescrita,
                        r_medicamento.precio_historico;
                end loop;

            end loop; -- fin tratamientos

        end loop; -- fin diagnosticos

    end loop; -- fin consultas

    raise notice '';
    raise notice '==================================================';
    raise notice 'Fin del historial clinico de %', v_nombre_mascota;
    raise notice '==================================================';
end;
$$;



-- ============================================================
-- 2. sp_registrar_mascota
-- Registrar una mascota nueva en el sistema
-- ============================================================
create or replace procedure sp_registrar_mascota(
    p_id_propietario        bigint,
    p_id_raza               bigint,
    p_nombre                varchar(255),
    p_sexo                  char(1),
    p_peso_actual           numeric(7,2),
    p_fecha_nacimiento      date,
    p_estado_reproductivo   varchar(255),
    p_descripcion_fisica    text
)
language plpgsql
as $$
declare
    v_id_propietario    bigint;
    v_id_raza           bigint;
begin
    -- verificar que el propietario existe
    select pr.id_propietario
    into v_id_propietario
    from propietario pr
    where pr.id_propietario = p_id_propietario;

    if not found then
        raise exception 'Propietario no existe';
    end if;

    -- verificar que la raza existe
    select r.id_raza
    into v_id_raza
    from raza r
    where r.id_raza = p_id_raza;

    if not found then
        raise exception 'Raza no existe';
    end if;

    -- insertar la nueva mascota
    insert into mascota(id_propietario, id_raza, nombre, sexo, peso_actual, fecha_nacimiento, estado_reproductivo, descripcion_fisica)
    values (p_id_propietario, p_id_raza, p_nombre, p_sexo, p_peso_actual, p_fecha_nacimiento, p_estado_reproductivo, p_descripcion_fisica);

    raise notice '% ha sido agregado con éxito al sistema', p_nombre;
end;
$$;


-- ============================================================
-- 3. sp_registrar_consulta
-- Registra una nueva consulta para una mascota
-- ============================================================
create or replace procedure sp_registrar_consulta(
    p_id_mascota        bigint,
    p_id_veterinario    bigint,
    p_fecha_hora_inicio timestamp,
    p_motivo            varchar(255),
    p_costo_consulta    numeric(10,2)
)
language plpgsql
as $$
declare
    v_id_mascota        bigint;
    v_id_veterinario    bigint;
begin
    -- verificar que la mascota existe
    select m.id_mascota
    into v_id_mascota
    from mascota m
    where m.id_mascota = p_id_mascota;

    if not found then
        raise exception 'La mascota con id % no existe', p_id_mascota;
    end if;

    -- verificar que el veterinario existe
    select v.id_veterinario
    into v_id_veterinario
    from veterinario v
    where v.id_veterinario = p_id_veterinario;

    if not found then
        raise exception 'El veterinario con id % no existe', p_id_veterinario;
    end if;

    -- registrar la consulta
    insert into consulta(id_mascota, id_veterinario, fecha_hora_inicio, motivo, costo_consulta, estado)
    values (p_id_mascota, p_id_veterinario, p_fecha_hora_inicio, p_motivo, p_costo_consulta, 'Pendiente');

    raise notice 'Consulta registrada con éxito para la mascota %', p_id_mascota;

exception
    when others then
        rollback;
        raise exception 'Error al registrar la consulta: %', sqlerrm;
end;
$$;