WITH user_stats AS (
    SELECT u.id,
           u.full_name,
           count(m.id)                              AS measurements_total,   -- всего строк параметров
           count(m.id) FILTER (WHERE m.has_error)   AS measurements_with_err, -- строк с ошибкой
           coalesce(sum(m.error_count), 0)          AS errors_total          -- всего ошибок
    FROM   meteo.users u
    JOIN   meteo.measurements m ON m.user_id = u.id
    GROUP  BY u.id, u.full_name
),
ranked AS (
    SELECT us.*,
           dense_rank() OVER (ORDER BY us.errors_total ASC)  AS place,
           count(*)     OVER ()                              AS shooters_count
    FROM   user_stats us
)
SELECT r.place                         AS "Место",
       r.full_name                     AS "Пользователь",
       r.measurements_total            AS "Всего измерений",
       r.measurements_with_err         AS "Измерений с ошибками",
       r.errors_total                  AS "Количество ошибок",
       CASE WHEN r.place = 1 THEN 'Лучший стрелок' ELSE '' END AS "Отметка"
FROM   ranked r
ORDER  BY r.place, r.full_name;
