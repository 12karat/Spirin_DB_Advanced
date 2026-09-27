-- Создаем справочник базовых единиц измерения
CREATE TABLE base_units (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

-- Создаем справочник единиц измерения
CREATE TABLE measurement_units (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    base_unit_id INT NOT NULL REFERENCES base_units(id) ON DELETE RESTRICT,
    name VARCHAR(30) NOT NULL
);

-- Создаем справочник типов параметров
CREATE TABLE parameter_types (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

-- Добавляем новые внешние ключи в таблицу параметров
ALTER TABLE parameters 
    ADD COLUMN parameter_type_id INT REFERENCES parameter_types(id) ON DELETE RESTRICT,
    ADD COLUMN unit_id INT REFERENCES measurement_units(id) ON DELETE RESTRICT;

-- Добавляем колонку даты измерения в таблицу партий
ALTER TABLE batches 
    ADD COLUMN measured_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Заполняем справочник типов параметров
INSERT INTO parameter_types (name) VALUES 
('Физический'),
('Климатический');

-- Заполняем справочник базовых единиц измерения
INSERT INTO base_units (name) VALUES 
('Давление'),
('Относительная влажность');

-- Заполняем справочник единиц измерения
INSERT INTO measurement_units (base_unit_id, name) VALUES 
(1, 'Бар'),
(2, '%');

-- Привязываем типы и единицы измерения к существующим параметрам
UPDATE parameters 
SET parameter_type_id = 1, unit_id = 1 
WHERE id = 1;

UPDATE parameters 
SET parameter_type_id = 2, unit_id = 2 
WHERE id = 2;

-- Заполняем даты измерений для существующих партий
UPDATE batches SET measured_at = '2026-09-27 10:00:00+00' WHERE id = 1;
UPDATE batches SET measured_at = '2026-09-27 11:30:00+00' WHERE id = 2;

-- Удаляем старое текстовое поле единицы измерения из таблицы параметров
ALTER TABLE parameters DROP COLUMN measurement_unit;

-- Устанавливаем ограничение NOT NULL для новых колонок в параметрах
ALTER TABLE parameters 
    ALTER COLUMN parameter_type_id SET NOT NULL,
    ALTER COLUMN unit_id SET NOT NULL;

-- Выполняем итоговую выборку по стандарту ANSI-92
SELECT 
    bt.measured_at AS "Дата измерения",
    bt.code AS "Номер пачки",
    usr.name AS "ФИО сотрудника",
    prm.name || ' (' || mu.name || ')' AS "Наименование параметра и ед. измерения",
    bt.measured_value AS "Значение"
FROM batches bt
INNER JOIN users usr ON bt.operator_id = usr.id
INNER JOIN parameters prm ON bt.parameter_id = prm.id
INNER JOIN measurement_units mu ON prm.unit_id = mu.id
INNER JOIN parameter_types pt ON prm.parameter_type_id = pt.id
ORDER BY bt.measured_at ASC;