-- Очистка только таблицы измерений перед повторным запуском
TRUNCATE TABLE batches RESTART IDENTITY CASCADE;

-- Добавление пачек измерений (каждая пачка содержит ровно 5 медицинских параметров)
-- Для каждого из 5 пользователей (ID 101..105) создаем по 2 пачки измерений
INSERT INTO batches (code, operator_id, equipment_type_id, parameter_id, measured_value, measured_at) VALUES
-- Пользователь 101 (Пачка 1)
('BATCH-101-1', 101, 1, 1, 36.6, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 08:00'),
('BATCH-101-1', 101, 1, 2, 72.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 08:00'),
('BATCH-101-1', 101, 1, 3, 120.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 08:00'),
('BATCH-101-1', 101, 1, 4, 80.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 08:00'),
('BATCH-101-1', 101, 1, 5, 98.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 08:00'),
-- Пользователь 101 (Пачка 2)
('BATCH-101-2', 101, 1, 1, 36.8, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 14:00'),
('BATCH-101-2', 101, 1, 2, 75.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 14:00'),
('BATCH-101-2', 101, 1, 3, 122.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 14:00'),
('BATCH-101-2', 101, 1, 4, 82.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 14:00'),
('BATCH-101-2', 101, 1, 5, 99.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 14:00'),

-- Пользователь 102 (Пачка 1)
('BATCH-102-1', 102, 1, 1, 36.5, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 09:00'),
('BATCH-102-1', 102, 1, 2, 68.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 09:00'),
('BATCH-102-1', 102, 1, 3, 118.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 09:00'),
('BATCH-102-1', 102, 1, 4, 78.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 09:00'),
('BATCH-102-1', 102, 1, 5, 97.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 09:00'),
-- Пользователь 102 (Пачка 2)
('BATCH-102-2', 102, 1, 1, 36.7, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '4 days 10:30'),
('BATCH-102-2', 102, 1, 2, 70.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '4 days 10:30'),
('BATCH-102-2', 102, 1, 3, 121.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '4 days 10:30'),
('BATCH-102-2', 102, 1, 4, 80.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '4 days 10:30'),
('BATCH-102-2', 102, 1, 5, 98.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '4 days 10:30'),

-- Пользователь 103 (Пачка 1)
('BATCH-103-1', 103, 1, 1, 37.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 08:15'),
('BATCH-103-1', 103, 1, 2, 80.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 08:15'),
('BATCH-103-1', 103, 1, 3, 130.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 08:15'),
('BATCH-103-1', 103, 1, 4, 85.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 08:15'),
('BATCH-103-1', 103, 1, 5, 96.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 08:15'),
-- Пользователь 103 (Пачка 2)
('BATCH-103-2', 103, 1, 1, 36.6, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '5 days 18:00'),
('BATCH-103-2', 103, 1, 2, 74.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '5 days 18:00'),
('BATCH-103-2', 103, 1, 3, 125.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '5 days 18:00'),
('BATCH-103-2', 103, 1, 4, 80.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '5 days 18:00'),
('BATCH-103-2', 103, 1, 5, 98.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '5 days 18:00'),

-- Пользователь 104 (Пачка 1)
('BATCH-104-1', 104, 1, 1, 36.4, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 11:00'),
('BATCH-104-1', 104, 1, 2, 65.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 11:00'),
('BATCH-104-1', 104, 1, 3, 115.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 11:00'),
('BATCH-104-1', 104, 1, 4, 75.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 11:00'),
('BATCH-104-1', 104, 1, 5, 99.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 11:00'),
-- Пользователь 104 (Пачка 2)
('BATCH-104-2', 104, 1, 1, 36.6, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '6 days 12:00'),
('BATCH-104-2', 104, 1, 2, 67.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '6 days 12:00'),
('BATCH-104-2', 104, 1, 3, 118.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '6 days 12:00'),
('BATCH-104-2', 104, 1, 4, 76.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '6 days 12:00'),
('BATCH-104-2', 104, 1, 5, 100.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '6 days 12:00'),

-- Пользователь 105 (Пачка 1)
('BATCH-105-1', 105, 1, 1, 36.9, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 07:30'),
('BATCH-105-1', 105, 1, 2, 78.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 07:30'),
('BATCH-105-1', 105, 1, 3, 124.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 07:30'),
('BATCH-105-1', 105, 1, 4, 81.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 07:30'),
('BATCH-105-1', 105, 1, 5, 97.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 07:30'),
-- Пользователь 105 (Пачка 2)
('BATCH-105-2', 105, 1, 1, 36.6, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '7 days 16:45'),
('BATCH-105-2', 105, 1, 2, 72.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '7 days 16:45'),
('BATCH-105-2', 105, 1, 3, 119.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '7 days 16:45'),
('BATCH-105-2', 105, 1, 4, 79.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '7 days 16:45'),
('BATCH-105-2', 105, 1, 5, 98.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '7 days 16:45');