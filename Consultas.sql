-- 1. Listado de propietarios con sus mascotas, especie y raza.
SELECT
    p.id_propietario,
    p.nombre AS nombre_propietario,
    p.apellido AS apellido_propietario,
    m.id_mascota,
    m.nombre AS nombre_mascota,
    e.nombre AS especie,
    r.nombre AS raza
FROM propietario p
INNER JOIN mascota m ON p.id_propietario = m.id_propietario
INNER JOIN raza r ON m.id_raza = r.id_raza
INNER JOIN especie e ON r.id_especie = e.id_especie
ORDER BY p.id_propietario, m.id_mascota;


-- 2. Mascotas más atendidas por mes.
SELECT
    DATE_TRUNC('month', c.fecha_hora_inicio)::date AS mes,
    m.id_mascota,
    m.nombre AS mascota,
    COUNT(c.id_consulta) AS total_atenciones
FROM consulta c
INNER JOIN mascota m ON c.id_mascota = m.id_mascota
GROUP BY DATE_TRUNC('month', c.fecha_hora_inicio), m.id_mascota, m.nombre
ORDER BY mes, total_atenciones DESC, mascota;

-- 3. Veterinario con mayor número de consultas por trimestre.
WITH consultas_por_trimestre AS (
    SELECT
        DATE_TRUNC('quarter', c.fecha_hora_inicio)::date AS trimestre,
        v.id_veterinario,
        v.nombre || ' ' || v.apellidos AS veterinario,
        COUNT(c.id_consulta) AS total_consultas,
        RANK() OVER (
            PARTITION BY DATE_TRUNC('quarter', c.fecha_hora_inicio)
            ORDER BY COUNT(c.id_consulta) DESC
        ) AS posicion
    FROM consulta c
    INNER JOIN veterinario v ON c.id_veterinario = v.id_veterinario
    GROUP BY DATE_TRUNC('quarter', c.fecha_hora_inicio), v.id_veterinario, v.nombre, v.apellidos
)
SELECT
    trimestre,
    id_veterinario,
    veterinario,
    total_consultas
FROM consultas_por_trimestre
WHERE posicion = 1
ORDER BY trimestre;

-- 4. Medicamentos prescritos con mayor frecuencia.
SELECT
    med.id_medicamento,
    med.nombre AS medicamento,
    med.marca,
    COUNT(tm.id_medicamento) AS veces_prescrito,
    SUM(tm.cantidad_prescrita) AS cantidad_total_prescrita
FROM tratamiento_medicamento tm
INNER JOIN medicamento med ON tm.id_medicamento = med.id_medicamento
GROUP BY med.id_medicamento, med.nombre, med.marca
ORDER BY veces_prescrito DESC, cantidad_total_prescrita DESC, medicamento;

-- 5. Ingresos totales por especialidad veterinaria.
SELECT
    esp.id_especialidad,
    esp.nombre AS especialidad,
    COUNT(DISTINCT c.id_consulta) AS total_consultas,
    SUM(f.total_a_pagar) AS ingresos_totales
FROM especialidad esp
INNER JOIN veterinario v ON esp.id_especialidad = v.id_especialidad
INNER JOIN consulta c ON v.id_veterinario = c.id_veterinario
INNER JOIN factura f ON c.id_consulta = f.id_consulta
GROUP BY esp.id_especialidad, esp.nombre
ORDER BY ingresos_totales DESC;

-- 6. Propietarios con mascotas que no han asistido a consultas en los últimos 6 meses.
SELECT
    p.id_propietario,
    p.nombre || ' ' || p.apellido AS propietario,
    m.id_mascota,
    m.nombre AS mascota
FROM propietario p
INNER JOIN mascota m ON p.id_propietario = m.id_propietario
WHERE NOT EXISTS (
    SELECT 1
    FROM consulta c
    WHERE c.id_mascota = m.id_mascota
      AND c.fecha_hora_inicio >= CURRENT_DATE - INTERVAL '6 months'
)
ORDER BY propietario, mascota;

-- 7. Mascotas con alergias registradas y medicamento asociado.
SELECT
    m.id_mascota,
    m.nombre AS mascota,
    p.nombre || ' ' || p.apellido AS propietario,
    med.nombre AS medicamento,
    ma.severidad,
    ma.reaccion,
    ma.fecha_deteccion
FROM mascota_alergia ma
INNER JOIN mascota m ON ma.id_mascota = m.id_mascota
INNER JOIN propietario p ON m.id_propietario = p.id_propietario
INNER JOIN medicamento med ON ma.id_medicamento = med.id_medicamento
ORDER BY ma.severidad, m.nombre;


-- 8. Propietarios que tienen más de una mascota.
SELECT
    p.id_propietario,
    p.nombre || ' ' || p.apellido AS propietario,
    COUNT(m.id_mascota) AS total_mascotas
FROM propietario p
INNER JOIN mascota m ON p.id_propietario = m.id_propietario
GROUP BY p.id_propietario, p.nombre, p.apellido
HAVING COUNT(m.id_mascota) > 1
ORDER BY total_mascotas DESC, propietario;


-- 9. Duración de consultas finalizadas.
SELECT
    c.id_consulta,
    m.nombre AS mascota,
    v.nombre || ' ' || v.apellidos AS veterinario,
    c.fecha_hora_inicio,
    c.fecha_hora_finalizar,
    c.fecha_hora_finalizar - c.fecha_hora_inicio AS duracion
FROM consulta c
INNER JOIN mascota m ON c.id_mascota = m.id_mascota
INNER JOIN veterinario v ON c.id_veterinario = v.id_veterinario
WHERE c.estado = 'Finalizada'
  AND c.fecha_hora_finalizar IS NOT NULL
ORDER BY duracion DESC;


-- 10. Medicamentos prescritos a mascotas que tienen alergia al mismo medicamento.
SELECT
    m.id_mascota,
    m.nombre AS mascota,
    med.id_medicamento,
    med.nombre AS medicamento,
    ma.severidad AS severidad_alergia,
    ma.reaccion,
    tm.dosis,
    tm.frecuencia,
    t.id_tratamiento
FROM tratamiento_medicamento tm
INNER JOIN medicamento med ON tm.id_medicamento = med.id_medicamento
INNER JOIN tratamiento t ON tm.id_tratamiento = t.id_tratamiento
INNER JOIN diagnostico d ON t.id_diagnostico = d.id_diagnostico
INNER JOIN consulta c ON d.id_consulta = c.id_consulta
INNER JOIN mascota m ON c.id_mascota = m.id_mascota
INNER JOIN mascota_alergia ma
    ON ma.id_mascota = m.id_mascota
   AND ma.id_medicamento = med.id_medicamento
ORDER BY ma.severidad, m.nombre, med.nombre;
