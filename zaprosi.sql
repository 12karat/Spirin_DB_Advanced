-- 1. Каждый пользователь имеет одинаковое количество измерений (пачек)?
SELECT 
    u.id AS user_id, 
    u.name AS user_name, 
    COUNT(DISTINCT b.code) AS total_batches
FROM users u
LEFT JOIN batches b ON u.id = b.operator_id
GROUP BY u.id, u.name
ORDER BY u.id;

-- 2. У нас нет пустых пачек измерения?
SELECT * 
FROM batches 
WHERE code IS NULL 
   OR operator_id IS NULL 
   OR parameter_id IS NULL 
   OR measured_value IS NULL;

-- 3. Каждая пачка измерений содержит полное количество параметров (5 шт)?
SELECT 
    code AS batch_code, 
    operator_id, 
    COUNT(parameter_id) AS parameters_count
FROM batches
GROUP BY code, operator_id
ORDER BY batch_code;

-- 4. Все значения, которые сформировал ИИ, корректны и в рамках нужного нам диапазона?
SELECT 
    p.name AS parameter_name,
    MIN(b.measured_value) AS min_value,
    MAX(b.measured_value) AS max_value,
    AVG(b.measured_value) AS avg_value
FROM batches b
JOIN parameters p ON b.parameter_id = p.id
GROUP BY p.name;

-- 5. Все единицы измерения верны и корректны по отношению к указанным параметрам?
SELECT DISTINCT
    p.name AS parameter_name,
    mu.name AS unit_name,
    bu.name AS base_unit_name
FROM batches b
JOIN parameters p ON b.parameter_id = p.id
JOIN measurement_units mu ON p.unit_id = mu.id
JOIN base_units bu ON mu.base_unit_id = bu.id
ORDER BY p.name;