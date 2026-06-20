-- =========================================================
-- Función 1: fn_calcular_edad_mascota
-- Retorna la edad de una mascota en años, calculada a partir
-- de su fecha de nacimiento. Si la mascota no existe o no
-- tiene fecha de nacimiento registrada, retorna null.
-- =========================================================
create or replace function fn_calcular_edad_mascota(p_id_mascota bigint)
returns int
language plpgsql
as $$
declare
    v_fecha_nacimiento  date;
    v_edad              int;
begin
    select m.fecha_nacimiento
    into v_fecha_nacimiento
    from mascota m
    where m.id_mascota = p_id_mascota;

    if not found then
        raise exception 'No existe una mascota con id %', p_id_mascota;
    end if;

    if v_fecha_nacimiento is null then
        return null;
    end if;

    v_edad := date_part('year', age(current_date, v_fecha_nacimiento));

    return v_edad;
end;
$$;


-- =========================================================
-- Función 2: fn_tiene_alergia
-- Retorna true si la mascota indicada tiene una alergia
-- registrada hacia el medicamento indicado, false en caso
-- contrario.
-- =========================================================
create or replace function fn_tiene_alergia(p_id_mascota bigint, p_id_medicamento bigint)
returns boolean
language plpgsql
as $$
declare
    v_existe    bigint;
begin
    select ma.id_mascota
    into v_existe
    from mascota_alergia ma
    where ma.id_mascota = p_id_mascota
      and ma.id_medicamento = p_id_medicamento;

    if found then
        return true;
    else
        return false;
    end if;
end;
$$;


-- =========================================================
-- Función 3: fn_total_facturado_mascota
-- Retorna el total acumulado en facturas de todas las
-- consultas asociadas a una mascota. Si la mascota no tiene
-- facturas registradas, retorna 0.
-- =========================================================
create or replace function fn_total_facturado_mascota(p_id_mascota bigint)
returns numeric(10,2)
language plpgsql
as $$
declare
    v_id_mascota    bigint;
    v_total         numeric(10,2);
begin
    select m.id_mascota
    into v_id_mascota
    from mascota m
    where m.id_mascota = p_id_mascota;

    if not found then
        raise exception 'No existe una mascota con id %', p_id_mascota;
    end if;

    select coalesce(sum(f.total_a_pagar), 0)
    into v_total
    from factura f
    join consulta c on c.id_consulta = f.id_consulta
    where c.id_mascota = p_id_mascota;

    return v_total;
end;
$$;
