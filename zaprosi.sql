-- 1. Количество измерений по каждому пользователю
SELECT u.id, u.name, COUNT(b.id) AS total_batches
FROM users u
LEFT JOIN batches b ON u.id = b.operator_id
GROUP BY u.id, u.name
ORDER BY u.id;

-- 2. Проверка отсутствия пустых/ошибочных записей
SELECT * FROM batches 
WHERE operator_id IS NULL OR parameter_id IS NULL;

-- 3. Количество измерений по каждому параметру
SELECT p.name AS parameter_name, COUNT(b.id) AS total_measurements
FROM parameters p
LEFT JOIN batches b ON p.id = b.parameter_id
GROUP BY p.name
ORDER BY p.name;

-- 4. Список всех параметров и их типов
SELECT p.id, p.name AS parameter_name, pt.name AS type_name
FROM parameters p
JOIN parameter_types pt ON p.parameter_type_id = pt.id
ORDER BY p.id;

-- 5. Единицы измерения параметров и их базовые величины
SELECT p.name AS parameter_name, mu.name AS unit_symbol, bu.name AS base_unit_name
FROM parameters p
JOIN measurement_units mu ON p.unit_id = mu.id
JOIN base_units bu ON mu.base_unit_id = bu.id
ORDER BY p.id;