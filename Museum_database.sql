CREATE DATABASE museum;

CREATE SCHEMA IF NOT EXISTS museum_data ;

CREATE TABLE IF NOT EXISTS museum_data.type_of_exhibit(
type_id serial PRIMARY KEY,
name_of_type VARCHAR(20) NOT NULL UNIQUE);

CREATE TABLE IF NOT EXISTS museum_data.exhibit_inventory(
inventory_number serial PRIMARY KEY,
type_id int REFERENCES museum_data.type_of_exhibit(type_id),
description_of_exhibit TEXT NOT NULL,
year_of_creation int DEFAULT 0000 );

CREATE TABLE IF NOT EXISTS museum_data.exhibition(
exhibition_id serial PRIMARY KEY,
exhibition_name TEXT NOT NULL UNIQUE,
description_of_exhibition TEXT NOT NULL,
age_restrictions int NOT NULL, 
date_of_start date NOT NULL,
date_of_finish date NOT NULL DEFAULT current_date);

CREATE TABLE IF NOT EXISTS museum_data.exhibition_inventory(
exhibition_id int REFERENCES museum_data.exhibition(exhibition_id),
inventory_number int REFERENCES museum_data.exhibit_inventory(inventory_number));

CREATE TABLE IF NOT EXISTS museum_data.visitor(
visitor_id serial PRIMARY KEY,
visitor_name VARCHAR(20) NOT NULL,
visitor_surname VARCHAR(20) NOT NULL,
date_of_birth date NOT NULL,
telephone_number bigint NOT NULL,
email VARCHAR(45) NOT NULL);

CREATE TABLE IF NOT EXISTS museum_data.visitor_exhibition(
visitor_id int REFERENCES museum_data.visitor(visitor_id),
exhibition_id int REFERENCES museum_data.exhibition(exhibition_id),
date_of_visiting date NOT NULL DEFAULT current_date);
CREATE TABLE IF NOT EXISTS museum_data.employee_position(
position_id serial PRIMARY KEY,
position_name TEXT NOT NULL,
responsibilities TEXT NOT NULL);

CREATE TABLE IF NOT EXISTS museum_data.employee(
employee_id serial PRIMARY KEY,
employee_name VARCHAR(20) NOT NULL,
employee_surname VARCHAR(20) NOT NULL,
date_of_birth date NOT NULL,
telephone_number bigint NOT NULL,
email TEXT NOT null,
position_id int REFERENCES museum_data.employee_position (position_id));

CREATE TABLE IF NOT EXISTS museum_data.employee_exhibition(
employee_id int REFERENCES museum_data.employee(employee_id),
exhibition_id int REFERENCES museum_data.exhibition(exhibition_id));
--------------------------------------------------------------------------
--in order a code will be reusable, to drop constraints before creating them
ALTER TABLE museum_data.exhibition DROP CONSTRAINT IF EXISTS age_restrictions_positive;
ALTER TABLE museum_data.visitor_exhibition DROP CONSTRAINT IF EXISTS date_of_exhibition;
ALTER TABLE museum_data.exhibition DROP CONSTRAINT IF EXISTS correct_date;
ALTER TABLE museum_data.visitor_exhibition DROP CONSTRAINT IF EXISTS visiting_date;
ALTER TABLE museum_data.employee_position DROP CONSTRAINT IF EXISTS uniq_position_name;
ALTER TABLE museum_data.exhibition ADD CONSTRAINT age_restrictions_positive CHECK (age_restrictions >=0);
ALTER TABLE museum_data.exhibition ADD CONSTRAINT date_of_exhibition CHECK (date_of_start>'2024-01-01');
ALTER TABLE museum_data.exhibition ADD CONSTRAINT correct_date CHECK (date_of_start<date_of_finish) ;        
ALTER TABLE museum_data.visitor_exhibition ADD CONSTRAINT visiting_date CHECK (date_of_visiting>'2024-01-01');
ALTER TABLE museum_data.employee_position ADD CONSTRAINT uniq_position_name UNIQUE (position_name);
--------------------------------------------------------------------------------
INSERT INTO museum_data.type_of_exhibit(name_of_type)
VALUES ('sculpture'),
		('artifact'),
		('artwork'),
		('digital'),
		('sound'),
		('textile')
ON CONFLICT (name_of_type) DO NOTHING;
				
INSERT INTO museum_data.exhibit_inventory(type_id, description_of_exhibit, year_of_creation)	
SELECT 	toe.type_id, 'Marble, white, naked, man', 1890
FROM museum_data.type_of_exhibit toe
WHERE NOT EXISTS 
		(SELECT FROM museum_data.exhibit_inventory ei WHERE ei.type_id=toe.type_id)
		AND upper(toe.name_of_type)='SCULPTURE'
UNION ALL 
SELECT 	toe.type_id, 'A collection of pottery pieces from ancient Greece', 1952
FROM museum_data.type_of_exhibit toe
WHERE NOT EXISTS 
		(SELECT FROM museum_data.exhibit_inventory ei WHERE ei.type_id=toe.type_id)
		AND upper(toe.name_of_type)='ARTIFACT'
UNION ALL 
SELECT 	toe.type_id, 'The collection highlights the movement''s focus on light, color, and everyday subjects', 2000
FROM museum_data.type_of_exhibit toe
WHERE NOT EXISTS 
		(SELECT FROM museum_data.exhibit_inventory ei WHERE ei.type_id=toe.type_id)
		AND upper(toe.name_of_type)='ARTWORK'	
UNION ALL 
SELECT 	toe.type_id, 'An immersive VR experience that allows visitors to explore a historically accurate reconstruction of an ancient Roman city, complete with interactive elements and guided narratives', '2020'
FROM museum_data.type_of_exhibit toe
WHERE NOT EXISTS 
		(SELECT FROM museum_data.exhibit_inventory ei WHERE ei.type_id=toe.type_id)
		AND upper(toe.name_of_type)='DIGITAL'
UNION ALL 
SELECT 	toe.type_id, 'visitors can listen to traditional instruments, early recordings, and modern compositions', 2020
FROM museum_data.type_of_exhibit toe
WHERE NOT EXISTS 
		(SELECT FROM museum_data.exhibit_inventory ei WHERE ei.type_id=toe.type_id)
		AND upper(toe.name_of_type)='SOUND'
UNION ALL 
SELECT 	toe.type_id, 'A display of traditional textiles from around the world', 2010
FROM museum_data.type_of_exhibit toe
WHERE NOT EXISTS 
		(SELECT FROM museum_data.exhibit_inventory ei WHERE ei.type_id=toe.type_id)
		AND upper(toe.name_of_type)='TEXTILE';	

INSERT INTO museum_data.exhibition(exhibition_name, description_of_exhibition, age_restrictions, date_of_start, date_of_finish)
VALUES ('The Wonders of Ancient Egypt', 'This exhibition takes visitors on a journey through the history and culture of Ancient Egypt', 3, '2024-02-01','2024-04-01'),
		('Impressionist Masterpieces', 'Showcasing the works of prominent Impressionist artists such as Claude Monet, Edgar Degas, and Pierre-Auguste Renoir', 12, '2024-01-05','2024-02-01'),
		('Digital Dreams: The Art of Virtual Reality',' Explore the cutting-edge world of digital art and virtual reality in this interactive exhibition', 7, '2024-01-11','2024-03-01'),
		('The Sound of History: Musical Instruments Through the Ages','This exhibition traces the evolution of musical instruments from ancient times to the present day', 15, '2024-03-11','2024-05-01'),
		('Threads of Time: A Journey Through Textile Arts','showcases the beauty and diversity of textile arts from around the world', 5,'2024-02-11','2024-04-21'),
		('Artifacts of the Americas: Pre-Columbian Treasures','Delve into the rich history and cultures of the Americas before the arrival of Columbus', 3,'2024-02-27','2024-03-21')
ON CONFLICT (exhibition_name) DO NOTHING;

INSERT INTO museum_data.exhibition_inventory (exhibition_id, inventory_number)
SELECT e.exhibition_id, ei.inventory_number
FROM museum_data.exhibition e
CROSS JOIN museum_data.exhibit_inventory ei
	WHERE NOT EXISTS (SELECT FROM museum_data.exhibition_inventory exi WHERE exi.exhibition_id=e.exhibition_id AND exi.inventory_number= ei.inventory_number)
	AND upper(e.exhibition_name)='THE WONDERS OF ANCIENT EGYPT' AND upper(ei.description_of_exhibit)='MARBLE, WHITE, NAKED, MAN'
UNION ALL 
SELECT e.exhibition_id, ei.inventory_number
FROM museum_data.exhibition e
CROSS JOIN museum_data.exhibit_inventory ei
	WHERE NOT EXISTS (SELECT FROM museum_data.exhibition_inventory exi WHERE exi.exhibition_id=e.exhibition_id AND exi.inventory_number= ei.inventory_number)
	AND upper(e.exhibition_name)='IMPRESSIONIST MASTERPIECES' AND upper(ei.description_of_exhibit)='THE COLLECTION HIGHLIGHTS THE MOVEMENT''S FOCUS ON LIGHT, COLOR, AND EVERYDAY SUBJECTS'
UNION ALL 
SELECT e.exhibition_id, ei.inventory_number
FROM museum_data.exhibition e
CROSS JOIN museum_data.exhibit_inventory ei
	WHERE NOT EXISTS (SELECT FROM museum_data.exhibition_inventory exi WHERE exi.exhibition_id=e.exhibition_id AND exi.inventory_number= ei.inventory_number)
	AND upper(e.exhibition_name)='DIGITAL DREAMS: THE ART OF VIRTUAL REALITY' AND upper(ei.description_of_exhibit)='AN IMMERSIVE VR EXPERIENCE THAT ALLOWS VISITORS TO EXPLORE A HISTORICALLY ACCURATE RECONSTRUCTION OF AN ANCIENT ROMAN CITY, COMPLETE WITH INTERACTIVE ELEMENTS AND GUIDED NARRATIVES'
UNION ALL 
SELECT e.exhibition_id, ei.inventory_number
FROM museum_data.exhibition e
CROSS JOIN museum_data.exhibit_inventory ei
	WHERE NOT EXISTS (SELECT FROM museum_data.exhibition_inventory exi WHERE exi.exhibition_id=e.exhibition_id AND exi.inventory_number= ei.inventory_number)
	AND upper(e.exhibition_name)='THE SOUND OF HISTORY: MUSICAL INSTRUMENTS THROUGH THE AGES' AND UPPER(EI.DESCRIPTION_OF_EXHIBIT)='VISITORS CAN LISTEN TO TRADITIONAL INSTRUMENTS, EARLY RECORDINGS, AND MODERN COMPOSITIONS'
UNION ALL 
SELECT e.exhibition_id, ei.inventory_number
FROM museum_data.exhibition e
CROSS JOIN museum_data.exhibit_inventory ei
	WHERE NOT EXISTS (SELECT FROM museum_data.exhibition_inventory exi WHERE exi.exhibition_id=e.exhibition_id AND exi.inventory_number= ei.inventory_number)
	AND upper(e.exhibition_name)='THREADS OF TIME: A JOURNEY THROUGH TEXTILE ARTS' AND upper(ei.description_of_exhibit)='A DISPLAY OF TRADITIONAL TEXTILES FROM AROUND THE WORLD'
UNION ALL 
SELECT e.exhibition_id, ei.inventory_number
FROM museum_data.exhibition e
CROSS JOIN museum_data.exhibit_inventory ei
	WHERE NOT EXISTS (SELECT FROM museum_data.exhibition_inventory exi WHERE exi.exhibition_id=e.exhibition_id AND exi.inventory_number= ei.inventory_number)
	AND upper(e.exhibition_name)='ARTIFACTS OF THE AMERICAS: PRE-COLUMBIAN TREASURES' AND upper(ei.description_of_exhibit)='A COLLECTION OF POTTERY PIECES FROM ANCIENT GREECE';
	
INSERT INTO museum_data.visitor(visitor_name, visitor_surname, date_of_birth,telephone_number,email )
SELECT 'John', 'Smith', to_date('1985-03-15', 'yyyy-mm-dd'),5551234567, 'john.smith@example.com'
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor v WHERE upper(visitor_name)='JOHN' AND upper(visitor_surname)='SMITH')
	UNION ALL 
SELECT 'Emily', 'Johnson', to_date('1990-07-21', 'yyyy-mm-dd'),9876543, 'emily.johnson@example.com'
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor v WHERE upper(visitor_name)='EMILY' AND upper(visitor_surname)='JOHNSON')
UNION ALL 
SELECT 'Michael', 'Williams', to_date('1978-11-02', 'yyyy-mm-dd'),4567890, 'michael.williams@example.com'
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor v WHERE upper(visitor_name)='MICHAEL' AND upper(visitor_surname)='WILLIAMS')
UNION ALL 
SELECT 'Sarah', 'Brown', to_date('1989-05-10', 'yyyy-mm-dd'),2345678, 'sarah.brown@example.com'
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor v WHERE upper(visitor_name)='SARAH' AND upper(visitor_surname)='BROWN')
UNION ALL 
SELECT 'David', 'Jones', to_date('1983-09-28', 'yyyy-mm-dd'),8765432, 'david.jones@example.com'
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor v WHERE upper(visitor_name)='DAVID' AND upper(visitor_surname)='JONES')
UNION ALL 
SELECT 'Jennifer', 'Davis', to_date('1995-12-07', 'yyyy-mm-dd'),3456789, 'jennifer.davis@example.com'
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor v WHERE upper(visitor_name)='JENNIFER' AND upper(visitor_surname)='DAVIS');
			
INSERT INTO museum_data.visitor_exhibition (visitor_id, exhibition_id, date_of_visiting)
SELECT v.visitor_id, e.exhibition_id,to_date('2024-05-10', 'yyyy-mm-dd')
FROM museum_data.visitor v
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor_exhibition  ve WHERE v.visitor_id=ve.visitor_id AND  e.exhibition_id=ve.exhibition_id)
	AND upper(e.exhibition_name)='ARTIFACTS OF THE AMERICAS: PRE-COLUMBIAN TREASURES'AND upper(v.visitor_name)='JOHN' AND upper(v.visitor_surname)='SMITH' AND upper(v.email)='JOHN.SMITH@EXAMPLE.COM'
UNION ALL 
SELECT v.visitor_id, e.exhibition_id,to_date('2024-05-10', 'yyyy-mm-dd')
FROM museum_data.visitor v
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor_exhibition  ve WHERE v.visitor_id=ve.visitor_id AND  e.exhibition_id=ve.exhibition_id)
	AND upper(e.exhibition_name)='THREADS OF TIME: A JOURNEY THROUGH TEXTILE ARTS' AND upper(v.visitor_name)='EMILY' AND upper(v.visitor_surname)='JOHNSON' AND upper(v.email)='EMILY.JOHNSON@EXAMPLE.COM'
UNION ALL 
SELECT v.visitor_id, e.exhibition_id,to_date('2024-01-21', 'yyyy-mm-dd')
FROM museum_data.visitor v
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor_exhibition  ve WHERE v.visitor_id=ve.visitor_id AND  e.exhibition_id=ve.exhibition_id)
	AND upper(e.exhibition_name)='THE SOUND OF HISTORY: MUSICAL INSTRUMENTS THROUGH THE AGES' AND upper(v.visitor_name)='MICHAEL' AND upper(v.visitor_surname)='WILLIAMS' AND upper(v.email)='MICHAEL.WILLIAMS@EXAMPLE.COM'	
UNION ALL 
SELECT v.visitor_id, e.exhibition_id,to_date('2024-05-12', 'yyyy-mm-dd')
FROM museum_data.visitor v
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor_exhibition  ve WHERE v.visitor_id=ve.visitor_id AND  e.exhibition_id=ve.exhibition_id)
	AND upper(e.exhibition_name)='DIGITAL DREAMS: THE ART OF VIRTUAL REALITY' AND upper(v.visitor_name)='SARAH' AND upper(v.visitor_surname)='BROWN' AND upper(v.email)='SARAH.BROWN@EXAMPLE.COM'
UNION ALL 
SELECT v.visitor_id, e.exhibition_id,to_date('2024-03-05', 'yyyy-mm-dd')
FROM museum_data.visitor v
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor_exhibition  ve WHERE v.visitor_id=ve.visitor_id AND  e.exhibition_id=ve.exhibition_id)
	AND upper(e.exhibition_name)='IMPRESSIONIST MASTERPIECES' AND upper(v.visitor_name)='DAVID' AND upper(v.visitor_surname)='JONES' AND upper(v.email)='DAVID.JONES@EXAMPLE.COM'	
UNION ALL 
SELECT v.visitor_id, e.exhibition_id,to_date('2024-04-15', 'yyyy-mm-dd')
FROM museum_data.visitor v
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.visitor_exhibition ve WHERE v.visitor_id=ve.visitor_id AND  e.exhibition_id=ve.exhibition_id)
	AND upper(e.exhibition_name)='THE WONDERS OF ANCIENT EGYPT' AND upper(v.visitor_name)='JENNIFER' AND upper(v.visitor_surname)='DAVIS' AND upper(v.email)= 'JENNIFER.DAVIS@EXAMPLE.COM';
	
INSERT INTO museum_data.employee_position (position_name, responsibilities)
VALUES ('Curator', 'Curators are responsible for managing and developing the museum''s collection'),
('Registrar', 'Registrars are tasked with the documentation, cataloging, and inventory management of the museum''s collection'),
('Conservator','Conservators specialize in the preservation and restoration of artworks or artifacts'),
('Education Coordinator','Education Coordinators design and implement educational programs and activities for visitors of all ages'),
('Visitor Services Associate', 'Visitor Services Associates provide frontline support to museum visitors, assisting with ticketing, information inquiries, and visitor engagement'),
('Exhibition Designer','Exhibition Designers conceptualize and create the visual and spatial experience of museum exhibitions')
ON CONFLICT (position_name) DO NOTHING;

INSERT INTO museum_data.employee(employee_name, employee_surname, date_of_birth, telephone_number, email, position_id)
SELECT 'Alice', 'Johnson', to_date('1980-05-15', 'yyyy-mm-dd'),1234567, 'alice.johnson@example.com', ep.position_id
FROM museum_data.employee_position ep
	WHERE NOT EXISTS (SELECT FROM museum_data.employee e WHERE e.position_id=ep.position_id)
	AND lower(ep.position_name)='curator'
UNION ALL 
SELECT 'David', 'Smith', to_date('1975-10-15', 'yyyy-mm-dd'),9876543, 'david.smith@example.com', ep.position_id
FROM museum_data.employee_position ep
	WHERE NOT EXISTS (SELECT FROM museum_data.employee e WHERE e.position_id=ep.position_id)
	AND lower(ep.position_name)='registrar'
UNION ALL 
SELECT 'Emily', 'Brown', to_date('1988-02-28', 'yyyy-mm-dd'),2345678, 'emily.brown@example.com', ep.position_id
FROM museum_data.employee_position ep
	WHERE NOT EXISTS (SELECT FROM museum_data.employee e WHERE e.position_id=ep.position_id)
	AND lower(ep.position_name)='conservator'	
UNION ALL 
SELECT 'Michael', 'Davis', to_date('1983-08-12', 'yyyy-mm-dd'),3456789, 'michael.davis@example.com', ep.position_id
FROM museum_data.employee_position ep
	WHERE NOT EXISTS (SELECT FROM museum_data.employee e WHERE e.position_id=ep.position_id)
	AND lower(ep.position_name)='education coordinator'	
UNION ALL 
SELECT 'Sarah', 'Wilson', to_date('1990-04-03', 'yyyy-mm-dd'),4567890, 'sarah.wilson@example.com', ep.position_id
FROM museum_data.employee_position ep
	WHERE NOT EXISTS (SELECT FROM museum_data.employee e WHERE e.position_id=ep.position_id)
	AND lower(ep.position_name)='visitor services associate'	
UNION ALL 
SELECT 'Matthew', 'Taylor', to_date('1979-11-17', 'yyyy-mm-dd'),5678901, 'matthew.taylor@example.com', ep.position_id
FROM museum_data.employee_position ep
	WHERE NOT EXISTS (SELECT FROM museum_data.employee e WHERE e.position_id=ep.position_id)
	AND lower(ep.position_name)='exhibition designer'	;

INSERT INTO museum_data.employee_exhibition(employee_id, exhibition_id)
SELECT em.employee_id, e.exhibition_id 
FROM museum_data.employee em
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.employee_exhibition ex WHERE em.employee_id=ex.employee_id AND e.exhibition_id= ex.exhibition_id )
	AND lower(em.employee_name)='matthew' AND  lower(em.employee_surname)='taylor' AND  em.telephone_number=5678901  AND upper(e.exhibition_name)='THE WONDERS OF ANCIENT EGYPT'
UNION ALL 
SELECT em.employee_id, e.exhibition_id 
FROM museum_data.employee em
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.employee_exhibition ex WHERE em.employee_id= ex.employee_id AND e.exhibition_id= ex.exhibition_id )
	AND lower(em.employee_name)= 'sarah' AND  lower(em.employee_surname)='wilson' AND  em.telephone_number=4567890  AND upper(e.exhibition_name)='IMPRESSIONIST MASTERPIECES'
UNION ALL 
SELECT em.employee_id, e.exhibition_id 
FROM museum_data.employee em
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.employee_exhibition ex WHERE em.employee_id= ex.employee_id AND e.exhibition_id= ex.exhibition_id )
	AND lower(em.employee_name)= 'michael' AND  lower(em.employee_surname)='davis' AND  em.telephone_number=3456789 AND upper(e.exhibition_name)='DIGITAL DREAMS: THE ART OF VIRTUAL REALITY'
UNION ALL 
SELECT em.employee_id, e.exhibition_id 
FROM museum_data.employee em
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.employee_exhibition ex WHERE em.employee_id= ex.employee_id AND e.exhibition_id= ex.exhibition_id )
	AND lower(em.employee_name)= 'alice' AND  lower(em.employee_surname)='johnson' AND  em.telephone_number=1234567 AND upper(e.exhibition_name)='THE SOUND OF HISTORY: MUSICAL INSTRUMENTS THROUGH THE AGES'
UNION ALL 
SELECT em.employee_id, e.exhibition_id 
FROM museum_data.employee em
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.employee_exhibition ex WHERE em.employee_id= ex.employee_id AND e.exhibition_id= ex.exhibition_id )
	AND lower(em.employee_name)= 'david' AND  lower(em.employee_surname)='smith' AND  em.telephone_number=9876543 AND upper(e.exhibition_name)='THREADS OF TIME: A JOURNEY THROUGH TEXTILE ARTS'
UNION ALL 
SELECT em.employee_id, e.exhibition_id 
FROM museum_data.employee em
CROSS JOIN museum_data.exhibition e
	WHERE NOT EXISTS (SELECT FROM museum_data.employee_exhibition ex WHERE em.employee_id= ex.employee_id AND e.exhibition_id= ex.exhibition_id )
	AND lower(em.employee_name)= 'emily' AND  lower(em.employee_surname)='brown' AND  em.telephone_number=2345678 AND upper(e.exhibition_name)='ARTIFACTS OF THE AMERICAS: PRE-COLUMBIAN TREASURES'	;	
-----------------------------------------------------------------
-- a function that updates data in one of your tables
CREATE OR REPLACE FUNCTION update_data_employee (p_key int, column_name text, new_value TEXT)
RETURNS void
LANGUAGE plpgsql
AS 
$$
BEGIN 
	--I made a query string with idetifier for column name %I, new data which I want to insert $1 and where clause with employee_id value which is needed to change $2
	EXECUTE FORMAT ('update museum_data.employee set %I=$1 where employee_id=$2', column_name )
	USING new_value, p_key;
	IF NOT FOUND THEN RAISE NOTICE 'column with % employee_id is not found', p_key;
	END IF;
END;
$$;
SELECT update_data_employee(1, 'employee_name', 'Nastya');
-----------------------------------------------------------------	
--	a function that adds a new transaction to your transaction table. 
CREATE OR REPLACE FUNCTION new_data_about_visitors ("name" TEXT, surname TEXT, birthday date, connection_number bigint, email_address text)
RETURNS void
LANGUAGE plpgsql
AS 
$$
BEGIN 
INSERT INTO museum_data.visitor(visitor_name, visitor_surname, date_of_birth,telephone_number,email )
VALUES  ("name", surname, birthday, connection_number, email_address);
RAISE NOTICE 'insertion is completed';
END;
$$;
	
SELECT new_data_about_visitors('Igor','Kuts',to_date('2000-02-09','yyy-mm-dd'),6594135, 'igorexample@mail.com');
----------------------------------------------------------
--the view contains data about exhibitions which were working during last quarter, how many people visited these exhibitions, how many workers organize them, 
--which exhibits were presented in these exhibitions.

CREATE OR REPLACE VIEW data_of_the_last_quarter AS
SELECT e.exhibition_name, e.age_restrictions, string_agg( ex.inventory_number::text, ', ') AS inventory_numbers, string_agg(ex.description_of_exhibit,', ') AS description_of_exhibits, 
string_agg(t.name_of_type, ', ') AS exhibits_type, count(ve.visitor_id) AS amount_of_people_who_visited_a_exhibition, count(DISTINCT em.employee_id) AS amount_of_people_who_organized_a_exhibition
FROM museum_data.exhibition e 
INNER JOIN museum_data.exhibition_inventory ei ON e.exhibition_id =ei.exhibition_id 
INNER JOIN museum_data.exhibit_inventory ex ON ex.inventory_number =ei.inventory_number 
INNER JOIN museum_data.type_of_exhibit t ON ex.type_id =t.type_id 
INNER JOIN museum_data.visitor_exhibition ve ON ve.exhibition_id =e.exhibition_id 
INNER JOIN museum_data.employee_exhibition em ON em.exhibition_id =e.exhibition_id 
WHERE extract(quarter FROM e.date_of_finish)=extract(quarter FROM current_date) AND extract(year FROM e.date_of_finish)=extract(year FROM current_date)
GROUP BY e.exhibition_name, e.age_restrictions
ORDER BY count(ve.visitor_id) DESC;

SELECT * FROM data_of_the_last_quarter;
