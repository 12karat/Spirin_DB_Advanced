-- Сначала удаляем старые таблицы, если они есть
DROP TABLE IF EXISTS batches CASCADE;
DROP TABLE IF EXISTS parameters CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS parameter_types CASCADE;
DROP TABLE IF EXISTS equipment_types CASCADE;
DROP TABLE IF EXISTS positions CASCADE;
DROP TABLE IF EXISTS measurement_units CASCADE;
DROP TABLE IF EXISTS base_units CASCADE;

-- Создаем таблицы

-- Базовые единицы
CREATE TABLE base_units (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Единицы измерения
CREATE TABLE measurement_units (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    base_unit_id INT NOT NULL REFERENCES base_units(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL
);

-- Должности
CREATE TABLE positions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Типы оборудования
CREATE TABLE equipment_types (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Типы параметров
CREATE TABLE parameter_types (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Пользователи
CREATE TABLE users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    position_id INT NOT NULL REFERENCES positions(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL
);

-- Параметры
CREATE TABLE parameters (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    parameter_type_id INT NOT NULL REFERENCES parameter_types(id) ON DELETE CASCADE,
    unit_id INT NOT NULL REFERENCES measurement_units(id) ON DELETE CASCADE
);

-- Таблица измерений
CREATE TABLE batches (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(255) NOT NULL,
    operator_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    equipment_type_id INT NOT NULL REFERENCES equipment_types(id) ON DELETE CASCADE,
    parameter_id INT NOT NULL REFERENCES parameters(id) ON DELETE CASCADE,
    measured_value NUMERIC NOT NULL,
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Заполняем таблицы данными

-- 1. Базовые единицы
INSERT INTO base_units (id, name) OVERRIDING SYSTEM VALUE VALUES
(1, 'Градус'),
(2, 'Удар'),
(3, 'Миллиметр ртутного столба'),
(4, 'Процент');

-- 2. Единицы измерения
INSERT INTO measurement_units (id, base_unit_id, name) OVERRIDING SYSTEM VALUE VALUES
(1, 1, '°C'),
(2, 2, 'bpm'),
(3, 3, 'mmHg'),
(4, 4, '%');

-- 3. Должности
INSERT INTO positions (id, name) OVERRIDING SYSTEM VALUE VALUES
(1, 'Пациент');

-- 4. Типы оборудования
INSERT INTO equipment_types (id, name) OVERRIDING SYSTEM VALUE VALUES
(1, 'Медицинский монитор');

-- 5. Типы параметров
INSERT INTO parameter_types (id, name) OVERRIDING SYSTEM VALUE VALUES
(1, 'Медицинские показатели');

-- 6. Пользователи (5 человек)
INSERT INTO users (id, position_id, name) OVERRIDING SYSTEM VALUE VALUES
(101, 1, 'Иван Иванов'),
(102, 1, 'Петр Петров'),
(103, 1, 'Сидор Сидоров'),
(104, 1, 'Алексей Алексеев'),
(105, 1, 'Михаил Михайлов');

-- 7. Параметры
INSERT INTO parameters (id, name, parameter_type_id, unit_id) OVERRIDING SYSTEM VALUE VALUES
(1, 'Температура', 1, 1),
(2, 'Пульс', 1, 2),
(3, 'Систолическое АД', 1, 3),
(4, 'Диастолическое АД', 1, 3),
(5, 'Уровень кислорода', 1, 4);

-- 8. Измерения (по 3 на каждого пользователя)
INSERT INTO batches (id, code, operator_id, equipment_type_id, parameter_id, measured_value, measured_at) OVERRIDING SYSTEM VALUE VALUES
(1,  'BATCH-001', 101, 1, 1, 36.6, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 08:30'),
(2,  'BATCH-002', 101, 1, 2, 72.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 14:15'),
(3,  'BATCH-003', 101, 1, 3, 120.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '5 days 20:00'),

(4,  'BATCH-004', 102, 1, 1, 36.8, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 09:00'),
(5,  'BATCH-005', 102, 1, 2, 75.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '4 days 12:45'),
(6,  'BATCH-006', 102, 1, 3, 122.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '6 days 18:30'),

(7,  'BATCH-007', 103, 1, 1, 37.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '2 days 07:45'),
(8,  'BATCH-008', 103, 1, 2, 80.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '5 days 13:10'),
(9,  'BATCH-009', 103, 1, 3, 118.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '7 days 21:15'),

(10, 'BATCH-010', 104, 1, 1, 36.5, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '3 days 10:20'),
(11, 'BATCH-011', 104, 1, 2, 68.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '6 days 15:50'),
(12, 'BATCH-012', 104, 1, 3, 125.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '8 days 19:40'),

(13, 'BATCH-013', 105, 1, 1, 36.7, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 day 11:00'),
(14, 'BATCH-014', 105, 1, 4, 80.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '4 days 16:30'),
(15, 'BATCH-015', 105, 1, 5, 98.0, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '7 days 22:00');