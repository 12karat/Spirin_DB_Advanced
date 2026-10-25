WITH params AS (
    SELECT 'N'::text   AS batch_code,      -- <-- подставьте код пачки
           false       AS only_errors
),
batch AS (
    SELECT b.id
    FROM   meteo.batches b
    JOIN   params p ON p.batch_code = b.code
),
src AS (
    SELECT m.id,
           et.name AS equipment_name,
           m.meteopost_height,
           m.temperature,
           m.pressure,
           m.wind_direction,
           m.wind_speed,
           m.bullet_drift_range,
           m.has_error,
           m.error_text
    FROM   meteo.measurements m
    JOIN   batch b                 ON b.id  = m.batch_id
    LEFT   JOIN meteo.equipment_types et ON et.id = m.equipment_type_id
),
filtered AS (
    SELECT s.*
    FROM   src s
    CROSS  JOIN params p
    WHERE  NOT p.only_errors OR s.has_error
),
numbered AS (
    SELECT f.*,
           row_number() OVER (ORDER BY f.id) AS rn
    FROM   filtered f
)
-- проекция: только нужные колонки с заголовками из задания
SELECT n.rn                                        AS "№",
       n.equipment_name                            AS "Тип оборудования",
       n.meteopost_height                          AS "Высота метеопоста",
       n.temperature                               AS "Температура",
       n.pressure                                  AS "Давление",
       n.wind_direction                            AS "Направление ветра",
       n.wind_speed                                AS "Скорость ветра",
       n.bullet_drift_range                        AS "Дальность сноса пуль",
       CASE WHEN n.has_error THEN 'Да' ELSE 'Нет' END AS "Флаг: Есть ошибка",
       n.error_text                                AS "Описание ошибки"
FROM   numbered n
ORDER  BY n.rn;
