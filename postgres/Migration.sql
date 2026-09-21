DROP TABLE IF EXISTS batches CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS positions CASCADE;
DROP TABLE IF EXISTS parameters CASCADE;
DROP TABLE IF EXISTS equipment_types CASCADE;

CREATE TABLE positions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

CREATE TABLE users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    position_id INT NOT NULL REFERENCES positions(id) ON DELETE RESTRICT,
    name VARCHAR(200) NOT NULL
);

CREATE TABLE equipment_types (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

CREATE TABLE parameters (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    measurement_unit VARCHAR(30) NOT NULL
);

CREATE TABLE batches (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,
    operator_id INT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    equipment_type_id INT NOT NULL REFERENCES equipment_types(id) ON DELETE RESTRICT,
    parameter_id INT NOT NULL REFERENCES parameters(id) ON DELETE RESTRICT,
    measured_value NUMERIC(10, 3) NOT NULL
);

INSERT INTO positions (name) VALUES 
('Старший смены'),
('Техник-наладчик');

INSERT INTO users (position_id, name) VALUES 
(1, 'Спирин В. А.'),
(2, 'Васильев Д. С.');

INSERT INTO equipment_types (name) VALUES 
('Термопластавтомат'),
('Пресс-форма');

INSERT INTO parameters (name, measurement_unit) VALUES 
('Давление', 'Бар'),
('Влажность', '%');

INSERT INTO batches (code, operator_id, equipment_type_id, parameter_id, measured_value) VALUES 
('L-9021', 1, 1, 1, 14.500),
('L-9022', 2, 2, 2, 62.300);

SELECT 
    bt.id AS batch_primary_id,
    bt.code AS batch_number,
    usr.name AS operator_name,
    pos.name AS position_title,
    eq.name AS equipment_category,
    prm.name AS metric_name,
    bt.measured_value AS metric_value,
    prm.measurement_unit AS unit_symbol
FROM batches bt
INNER JOIN users usr ON bt.operator_id = usr.id
INNER JOIN positions pos ON usr.position_id = pos.id
INNER JOIN equipment_types eq ON bt.equipment_type_id = eq.id
INNER JOIN parameters prm ON bt.parameter_id = prm.id;