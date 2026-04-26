--ENUMS

CREATE TYPE payment_method AS ENUM (
	'card',
	'cash',
	'wallet'
);


CREATE TYPE trip_status AS ENUM (
	'requested',
	'in_progress',
	'completed',
	'canceled'	
);

CREATE TYPE vehicle_type AS ENUM (
	'economic',
	'standard',
	'premium'

);

--USERS

CREATE TABLE users (
	user_id SERIAL PRIMARY KEY, -- SERIAL genera IDs automáticos,PK identifica cada rol
	name VARCHAR(100) NOT NULL,
	phone VARCHAR(20) NOT NULL,
	email VARCHAR (100) UNIQUE NOT NULL

);
--roles
-- roles define los tipos de usuario del sistema (ej: driver, passenger)
-- se separa en su propia tabla para permitir agregar nuevos roles sin modificar users


CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,  -- SERIAL genera IDs automáticos
    name VARCHAR(100) NOT NULL
    
);

--user roles
-- user_roles conecta users con roles (relación muchos a muchos)
-- un usuario puede tener varios roles y un rol puede pertenecer a varios usuarios

CREATE TABLE user_roles (
	user_id INT, --declaras las columnas antes de usarlos 
    role_id INT,
    PRIMARY KEY (user_id, role_id),--Evita duplicados
	FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,-- si borras un usuario se borran automáticamente sus roles asignados
	FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

-- drivers_profile es una extensión de usuarios
--si este usuario es conductor, aquí vive su info extra
CREATE TABLE drivers_profile (
	user_id INT PRIMARY KEY,
	license_number VARCHAR(100),
	license_expiration_date DATE,
	insurance_document VARCHAR(100),
	insurance_expiration_date DATE,
	FOREIGN KEY (user_id) REFERENCES users(user_id)	--FK va del lado de muchos 

);

--vehicles
-- vehicles almacena los autos de cada conductor (relación 1 a muchos)
-- solo usuarios con drivers_profile pueden tener vehículos

CREATE TABLE vehicles (
	vehicle_id SERIAL PRIMARY KEY,
	user_id INT,
	brand VARCHAR(100),
	model VARCHAR(100),
	year INT,
	plates VARCHAR(100),
	FOREIGN KEY (user_id) REFERENCES drivers_profile(user_id) -- solo usuarios con drivers_profile pueden tener vehículos
	
);

--trips
-- trips registra cada viaje conectando pasajero, conductor y vehículo
-- incluye estado, método de pago y tipo de vehículo mediante ENUMs

CREATE TABLE trips (
	trip_id SERIAL PRIMARY KEY,
	passenger_id INT,
	driver_id INT,
	vehicle_id INT,
	pick_up_location VARCHAR(100),
	destination  VARCHAR(100),
	payment_method payment_method,
	vehicle_type vehicle_type,
	start_time TIMESTAMP,
	end_time TIMESTAMP,
	route TEXT,
	distance NUMERIC,
	total_price NUMERIC NOT NULL,
	status trip_status NOT NULL,


	FOREIGN KEY (passenger_id) REFERENCES users(user_id),
	FOREIGN KEY (driver_id) REFERENCES drivers_profile(user_id), --referencia a la tabla drivers_profile
	FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
		
);

-- índices para mejorar el rendimiento en búsquedas por foreign keys
-- aceleran consultas como buscar viajes por pasajero o conductor

CREATE INDEX idx_trips_passenger ON trips(passenger_id);
CREATE INDEX idx_trips_driver ON trips(driver_id);
CREATE INDEX idx_trips_vehicle ON trips(vehicle_id);

--ratings
-- ratings guarda una evaluación por fila para mantener el diseño escalable
CREATE TABLE ratings(
	rating_id SERIAL PRIMARY KEY,
	rater_id INT ,
	rated_id INT,
	trip_id INT ,
	rating_value INT CHECK (rating_value BETWEEN 1 AND 5), -- CHECK valida que la puntuación solo esté entre 1 y 5
	comment TEXT,

	FOREIGN KEY (rater_id) REFERENCES users(user_id),
	FOREIGN KEY (rated_id) REFERENCES users(user_id),
	FOREIGN KEY (trip_id) REFERENCES trips(trip_id),
	UNIQUE (rater_id, trip_id) -- evita que un usuario califique más de una vez el mismo viaje
	
	
);

--reports
-- reports registra incidentes entre usuarios relacionados a un viaje

CREATE TABLE reports(
	report_id SERIAL PRIMARY KEY,
	reporter_id INT,
	reported_id INT,
	trip_id INT,
	description TEXT,
	incident_datetime TIMESTAMP,
	

	FOREIGN KEY (reporter_id) REFERENCES users(user_id),
	FOREIGN KEY (reported_id) REFERENCES users(user_id),
	FOREIGN KEY (trip_id) REFERENCES trips(trip_id),
	CHECK (reporter_id <> reported_id),--evita que un usuario se reporte a sí mismo
	UNIQUE (reporter_id, trip_id) -- evita reportes duplicados del mismo usuario en el mismo viaje
	
	
);


INSERT INTO users (name, phone, email) VALUES
('Juan Perez', '5511111111', 'juan@test.com'),
('Ana Lopez', '5522222222', 'ana@test.com'),
('Carlos Ruiz', '5533333333', 'carlos@test.com');

INSERT INTO roles (name) VALUES
('passenger'),
('driver');


INSERT INTO user_roles (user_id, role_id) VALUES
(1, 1), -- Juan pasajero
(2, 2), -- Ana conductora
(3, 1), -- Carlos pasajero
(3, 2); -- Carlos conductor


INSERT INTO drivers_profile (user_id, license_number, license_expiration_date, insurance_document, insurance_expiration_date) VALUES
(2, 'LIC123', '2027-01-01', 'INS123', '2026-01-01'),
(3, 'LIC456', '2027-06-01', 'INS456', '2026-06-01');

INSERT INTO vehicles (user_id, brand, model, year, plates) VALUES
(2, 'Toyota', 'Corolla', 2020, 'ABC123'),
(3, 'Honda', 'Civic', 2021, 'XYZ789');


INSERT INTO trips (
    passenger_id, driver_id, vehicle_id,
    pick_up_location, destination,
    payment_method, vehicle_type,
    start_time, end_time,
    route, distance, total_price, status
) VALUES
(1, 2, 1, 'Centro', 'Polanco', 'card', 'standard', NOW(), NOW(), 'Ruta 1', 10.5, 150, 'completed'),
(3, 2, 1, 'Roma', 'Condesa', 'cash', 'economic', NOW(), NOW(), 'Ruta 2', 5.2, 80, 'completed');


INSERT INTO ratings (rater_id, rated_id, trip_id, rating_value, comment) VALUES
(1, 2, 1, 5, 'Excelente servicio'),
(2, 1, 1, 5, 'Buen pasajero'),
(3, 2, 2, 4, 'Buen viaje'),
(2, 3, 2, 5, 'Muy puntual');


INSERT INTO reports (reporter_id, reported_id, trip_id, description, incident_datetime) VALUES
(1, 2, 1, 'Retraso leve', NOW()),
(3, 2, 2, 'Conducción brusca', NOW());