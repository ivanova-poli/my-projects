--CREATE DATABASE political_camp;
DROP SCHEMA polit_data CASCADE;
CREATE SCHEMA IF NOT EXISTS polit_data;

DROP TYPE IF EXISTS type_of_donor CASCADE;							--CREATE an enum DATATYPE 
CREATE TYPE type_of_donor AS ENUM ('individual', 'legal entity');

CREATE TABLE IF NOT EXISTS polit_data.campaign_donors (
campaign_donors_id serial ,
bank_book_number int NOT NULL,
name VARCHAR(20)  NOT NULL,
surname VARCHAR(20) DEFAULT ('This is a company'), 
type_of_donor type_of_donor NOT NULL,
CONSTRAINT PK_cd PRIMARY key(campaign_donors_id) );

DROP TYPE IF EXISTS type_of_income CASCADE;
CREATE TYPE type_of_income AS ENUM ('cash', 'sending money');

CREATE TABLE IF NOT EXISTS polit_data.finances_income (
finances_income_id serial PRIMARY KEY, 
type_of_income type_of_income NOT NULL 
);

CREATE TABLE IF NOT EXISTS polit_data.finances_campaign_donors(
financial_income_id int REFERENCES polit_data.finances_income(finances_income_id),
campaign_donor_id int REFERENCES polit_data.campaign_donors(campaign_donors_id),
--checking that number IN this COLUMN will be bigger 0(positive)
amount_of_income float(10) CONSTRAINT positive_income CHECK (amount_of_income>0) NOT NULL,  
PRIMARY KEY(financial_income_id)  
);

DROP TYPE IF EXISTS gender CASCADE;
CREATE TYPE gender AS ENUM ('male', 'female');

CREATE TABLE IF NOT EXISTS polit_data.candidates (
candidates_id serial PRIMARY KEY,
name VARCHAR(20) NOT NULL,
surname VARCHAR(20)NOT NULL,
gender gender NOT NULL,
date_of_birth date NOT NULL
);

CREATE TABLE IF NOT EXISTS polit_data.political_party(
political_party_id serial PRIMARY KEY,
name VARCHAR(45) UNIQUE NOT NULL  
);

CREATE TABLE IF NOT EXISTS polit_data.political_campaign (
political_campaign_id serial PRIMARY KEY , 
political_party_id int REFERENCES polit_data.political_party (political_party_id),
candidates_id int REFERENCES polit_data.candidates (candidates_id)
);

CREATE TABLE IF NOT EXISTS polit_data.street (
street_id serial PRIMARY KEY,
street_name VARCHAR(20) UNIQUE NOT NULL
);


CREATE TABLE IF NOT EXISTS polit_data.city (
city_id serial PRIMARY KEY,
city_name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS polit_data.district(
district_id serial PRIMARY KEY,
district_name VARCHAR(20) UNIQUE NOT NULL,
postcode_number VARCHAR(20) UNIQUE NOT NULL,
city_id int REFERENCES polit_data.city (city_id)
);

CREATE TABLE IF NOT EXISTS  polit_data.district_street (
district_street_id serial PRIMARY KEY,
district_id int REFERENCES polit_data.district(district_id),
street_id int REFERENCES polit_data.street(street_id)
);

CREATE TABLE IF NOT EXISTS polit_data.registration_info(
registration_id serial PRIMARY KEY, 
district_street_id int REFERENCES polit_data.district_street (district_street_id),
building_number VARCHAR(10) NOT NULL,
apartment_number VARCHAR(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS polit_data.people_info(  
--here PK IS NATURAL KEY, so it IS integer DATATYPE 
passport_number int PRIMARY KEY,
name VARCHAR(20) NOT NULL,
surname VARCHAR(20) NOT NULL,
date_of_birth date NOT NULL,
gender gender NOT NULL,
registration_id int REFERENCES polit_data.registration_info (registration_id) 		
);

DROP TYPE IF EXISTS type_of_votes CASCADE;
CREATE TYPE type_of_votes AS ENUM ('online', 'graphic');

CREATE TABLE IF NOT EXISTS polit_data.elections (
elections_id serial PRIMARY KEY,
address_id int REFERENCES polit_data.registration_info(registration_id),
voting_date date CONSTRAINT date_of_voting CHECK (voting_date>'2000-01-01')	NOT NULL,	
number_of_people_who_voted int NOT NULL,												
type_of_votes type_of_votes 															
);																						

CREATE TABLE IF NOT EXISTS polit_data.people_elections(
passport_number int REFERENCES polit_data.people_info (passport_number) ,
elections_id int REFERENCES polit_data.elections (elections_id)
);

CREATE TABLE IF NOT EXISTS polit_data.political_campaign_elections(
political_campaign_id int REFERENCES polit_data.political_campaign(political_campaign_id),
elections_id int REFERENCES polit_data.elections(elections_id),
number_of_votes_for_candidates int ,								
PRIMARY key(political_campaign_id, elections_id)					
);

CREATE TABLE IF NOT EXISTS polit_data.campaign_volunteers( 
campaign_volunteers_id serial PRIMARY KEY,
name VARCHAR(20) NOT NULL,
surname VARCHAR(20) NOT NULL,
date_of_birth date NOT NULL,
gender gender NOT NULL,
roles VARCHAR,
phone_number VARCHAR(20) ,
political_campaign_id int REFERENCES polit_data.political_campaign(political_campaign_id)
);

CREATE TABLE IF NOT EXISTS polit_data.elections_campaign_volunteers(
elections_id int REFERENCES polit_data.elections (elections_id),
campaign_volunteers_id int REFERENCES polit_data.campaign_volunteers(campaign_volunteers_id),
start_time timestamp NOT NULL,
end_time timestamp NOT NULL,
PRIMARY KEY (elections_id, campaign_volunteers_id));

DROP TYPE IF EXISTS type_of_event CASCADE;
CREATE TYPE  type_of_event AS ENUM ('online', 'offline' );

CREATE TABLE IF NOT EXISTS polit_data.events(
events_id serial PRIMARY KEY,
type_of_event type_of_event, 
number_of_spectators int,
number_of_mentions_on_social_networks int,
number_of_mentions_on_television int,            
date_of_events date 
);

CREATE TABLE IF NOT EXISTS polit_data.campaign_volunteers_events(
events_id  int REFERENCES polit_data.events (events_id),
campaign_volunteers_id int REFERENCES polit_data.campaign_volunteers(campaign_volunteers_id),
start_time timestamp NOT NULL,
end_time timestamp NOT NULL
);

CREATE TABLE IF NOT EXISTS polit_data.events_campaign (
events_id int REFERENCES polit_data.events(events_id),
political_campaign_id int REFERENCES polit_data.political_campaign(political_campaign_id),
PRIMARY KEY (events_id, political_campaign_id)
);




--------------INSERT---------------------------
INSERT INTO polit_data.campaign_donors (bank_book_number,  name, surname,type_of_donor)  
SELECT   456564, 'Oleg', 'Petrov', 'individual'::type_of_donor
WHERE NOT EXISTS (
    SELECT FROM polit_data.campaign_donors WHERE upper(name)= 'OLEG' AND upper(surname)='PETROV')
	UNION ALL
SELECT 45675,'White night', 'This is a company', 'legal entity'::type_of_donor
WHERE NOT EXISTS (
    SELECT FROM polit_data.campaign_donors WHERE upper(name)= 'WHITE NIGHT');
   
 
   
   --I couldn't use SELECT WHERE NOT EXISTS IN this CASE so this code NOT reusable. it ALWAYS produce NEW data
INSERT INTO polit_data.finances_income(type_of_income)
SELECT 'cash'::type_of_income
UNION ALL
SELECT 'sending money'::type_of_income
; 

INSERT INTO polit_data.finances_campaign_donors(financial_income_id, campaign_donor_id, amount_of_income)		 
SELECT  fi.finances_income_id, cd.campaign_donors_id, 23.45										
FROM polit_data.campaign_donors cd 
CROSS JOIN polit_data.finances_income fi 
	WHERE NOT EXISTS 
	(SELECT FROM polit_data.finances_campaign_donors fcd WHERE fcd.campaign_donor_id=cd.campaign_donors_id AND fi.finances_income_id=fcd.financial_income_id)
	AND fi.type_of_income='cash' AND cd.bank_book_number=456564
	UNION ALL 
SELECT  fi.finances_income_id, cd.campaign_donors_id, 3846.65
FROM polit_data.campaign_donors cd
CROSS JOIN polit_data.finances_income fi
	WHERE NOT EXISTS 
	(SELECT FROM polit_data.finances_campaign_donors fcd WHERE fcd.campaign_donor_id=cd.campaign_donors_id AND fi.finances_income_id=fcd.financial_income_id)
	AND fi.type_of_income='sending money' AND cd.bank_book_number=45675;

INSERT INTO polit_data.candidates ( name, surname, gender,date_of_birth )	--two ROWS OF data
SELECT  'Ivan', 'Ivanov', 'male'::gender, TO_DATE('1982-02-14','YYYY-MM-DD')
	WHERE NOT EXISTS (SELECT  FROM polit_data.candidates c WHERE upper(name)= 'IVAN' AND upper(surname)='IVANOV')
UNION ALL
SELECT  'Jon', 'Blue','male'::gender, TO_DATE('1966-02-20', 'YYYY-MM-DD')
	WHERE NOT EXISTS (SELECT  FROM polit_data.candidates c WHERE upper(name)= 'JON' AND upper(surname)='BLUE' );

INSERT INTO polit_data.political_party (name)
SELECT 'Apple'
	WHERE NOT EXISTS (SELECT political_party_id FROM polit_data.political_party WHERE  upper(name)='APPLE')
	UNION ALL 
SELECT 'Liberals'
	WHERE NOT EXISTS (SELECT political_party_id FROM polit_data.political_party WHERE upper(name)='LIBERALS');

INSERT INTO polit_data.political_campaign (political_party_id, candidates_id)  				  
SELECT pp.political_party_id, c.candidates_id						
FROM polit_data.candidates c
CROSS JOIN polit_data.political_party pp
	WHERE NOT EXISTS (SELECT  FROM polit_data.political_campaign pc WHERE pc.political_party_id=pp.political_party_id AND  pc.candidates_id=c.candidates_id)   
	AND upper(pp.name)='APPLE' AND upper(c.name) ='IVAN' AND upper(c.surname) ='IVANOV'
	UNION ALL 
SELECT pp.political_party_id, c.candidates_id						
FROM polit_data.candidates c
CROSS JOIN polit_data.political_party pp
	WHERE NOT EXISTS (SELECT  FROM polit_data.political_campaign pc WHERE pc.political_party_id=pp.political_party_id AND  pc.candidates_id=c.candidates_id)
	AND upper(pp.name)='LIBERALS' AND upper(c.name) ='JON' AND upper(c.surname) ='BLUE';

INSERT INTO polit_data.street (street_name)
SELECT 'Lenina'
	WHERE NOT EXISTS (SELECT FROM polit_data.street WHERE upper(street_name)='LENINA')
	UNION ALL 
SELECT 'Mex'
	WHERE NOT EXISTS (SELECT FROM polit_data.street WHERE upper(street_name)='MEX');

INSERT INTO polit_data.city (city_name)
SELECT 'Moscow'
	WHERE NOT EXISTS (SELECT FROM polit_data.city WHERE upper(city_name)='MOSCOW')
	UNION ALL 
SELECT 'Krakov'
	WHERE NOT EXISTS (SELECT FROM polit_data.city WHERE upper(city_name)='KRAKOV');

INSERT INTO polit_data.district(district_name, postcode_number, city_id)				
SELECT 'New_city', 'sd65971', c.city_id 
FROM polit_data.city c
	WHERE NOT EXISTS (SELECT * FROM polit_data.district d WHERE d.city_id=c.city_id)
	AND upper(c.city_name)='MOSCOW'
UNION ALL 
SELECT 'Market', '659fgy71', c.city_id  
FROM polit_data.city c
	WHERE NOT EXISTS (SELECT * FROM polit_data.district d WHERE d.city_id=c.city_id)
	AND upper(c.city_name)='KRAKOV';


INSERT INTO polit_data.district_street (district_id, street_id)
SELECT d.district_id, s.street_id 
FROM polit_data.district d
CROSS JOIN polit_data.street s
	WHERE  NOT EXISTS (SELECT FROM polit_data.district_street ds WHERE d.district_id=ds.district_id AND s.street_id=ds.street_id)
	AND upper(d.district_name)='MARKET' AND upper(s.street_name)='LENINA'
UNION ALL 
SELECT d.district_id, s.street_id 
FROM polit_data.district d
CROSS JOIN polit_data.street s
	WHERE  NOT EXISTS (SELECT FROM polit_data.district_street ds WHERE d.district_id=ds.district_id AND s.street_id=ds.street_id)
	AND upper(d.district_name)='NEW_CITY' AND upper(s.street_name)='MEX';

INSERT INTO polit_data.registration_info(district_street_id, building_number, apartment_number)		
SELECT ds.district_street_id,'45','98b'
FROM polit_data.district_street ds
INNER JOIN polit_data.district d ON ds.district_id=d.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
	WHERE NOT EXISTS (SELECT FROM polit_data.registration_info ri WHERE ds.district_street_id=ri.district_street_id)
	AND upper(d.district_name)='NEW_CITY' AND upper(s.street_name)='MEX'
	UNION ALL 
SELECT ds.district_street_id,'415c','90c'
FROM polit_data.district_street ds
INNER JOIN polit_data.district d ON ds.district_id=d.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
	WHERE NOT EXISTS (SELECT FROM polit_data.registration_info ri WHERE ds.district_street_id=ri.district_street_id)
	AND upper(d.district_name)='MARKET' AND upper(s.street_name)='LENINA'
; 

INSERT INTO polit_data.people_info (passport_number, "name", surname, date_of_birth, "gender", registration_id )
SELECT 456981, 'Petr', 'Petrov',to_date('1999-10-18','yyyy-mm-dd'),'male'::gender ,ri.registration_id
FROM polit_data.registration_info ri
INNER JOIN polit_data.district_street ds ON ds.district_street_id=ri.district_street_id
INNER JOIN polit_data.district d ON d.district_id=ds.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
	WHERE NOT EXISTS (SELECT FROM polit_data.people_info pi WHERE ri.registration_id =pi.registration_id)
	AND upper(d.district_name)='NEW_CITY' AND upper(s.street_name)='MEX'
	UNION ALL 
SELECT 961457, 'Olga', 'White',to_date('1988-06-18','yyyy-mm-dd'),'female'::gender ,ri.registration_id
FROM polit_data.registration_info ri
INNER JOIN polit_data.district_street ds ON ds.district_street_id=ri.district_street_id
INNER JOIN polit_data.district d ON d.district_id=ds.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
	WHERE NOT EXISTS (SELECT FROM polit_data.people_info pi WHERE ri.registration_id =pi.registration_id)
	AND upper(d.district_name)='MARKET' AND upper(s.street_name)='LENINA' ;

INSERT INTO polit_data.elections (address_id,voting_date, number_of_people_who_voted, type_of_votes)  
SELECT ri.registration_id ,to_date('2011-02-13', 'YYYY-MM-DD'), 15, 'online'::type_of_votes
FROM polit_data.registration_info ri 
INNER JOIN polit_data.district_street ds ON ds.district_street_id=ri.district_street_id
INNER JOIN polit_data.district d ON d.district_id=ds.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
	WHERE NOT EXISTS ( SELECT FROM polit_data.elections e WHERE ri.registration_id =e.address_id)
	AND upper(d.district_name)='MARKET' AND upper(s.street_name)='LENINA' 
	UNION ALL 
SELECT ri.registration_id ,to_date('2011-06-10','YYYY-MM-DD'), 155,'graphic'::type_of_votes
FROM polit_data.registration_info ri 
INNER JOIN polit_data.district_street ds ON ds.district_street_id=ri.district_street_id
INNER JOIN polit_data.district d ON d.district_id=ds.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
	WHERE NOT EXISTS ( SELECT FROM polit_data.elections e WHERE ri.registration_id =e.address_id)
	AND upper(d.district_name)='NEW_CITY' AND upper(s.street_name)='MEX';
	
INSERT INTO polit_data.people_elections (passport_number, elections_id)
SELECT pi.passport_number, e.elections_id
FROM polit_data.people_info pi
CROSS JOIN polit_data.elections e
INNER JOIN polit_data.registration_info ri ON ri.registration_id =e.address_id 
INNER JOIN polit_data.district_street ds ON ds.district_street_id=ri.district_street_id
INNER JOIN polit_data.district d ON d.district_id=ds.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
	WHERE NOT EXISTS (SELECT FROM polit_data.people_elections pe WHERE pe.passport_number=pi.passport_number AND e.elections_id=pe.elections_id)
	AND upper(d.district_name)='MARKET' AND upper(s.street_name)='LENINA' AND  pi.passport_number=961457
	UNION ALL 
SELECT pi.passport_number, e.elections_id
FROM polit_data.people_info pi
CROSS JOIN polit_data.elections e
INNER JOIN polit_data.registration_info ri ON ri.registration_id =e.address_id 
INNER JOIN polit_data.district_street ds ON ds.district_street_id=ri.district_street_id
INNER JOIN polit_data.district d ON d.district_id=ds.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
	WHERE NOT EXISTS (SELECT FROM polit_data.people_elections pe WHERE pe.passport_number=pi.passport_number AND e.elections_id=pe.elections_id)
	AND upper(d.district_name)='NEW_CITY' AND upper(s.street_name)='MEX' AND  pi.passport_number=456981;

INSERT INTO polit_data.political_campaign_elections (political_campaign_id, elections_id, number_of_votes_for_candidates )
SELECT pc.political_campaign_id, e.elections_id,35
FROM polit_data.political_campaign pc
INNER JOIN polit_data.political_party pp ON pp.political_party_id=pc.political_campaign_id 
CROSS JOIN polit_data.elections e
INNER JOIN polit_data.registration_info ri ON ri.registration_id=e.address_id 
INNER JOIN polit_data.district_street ds ON  ds.district_street_id =ri.district_street_id 
INNER JOIN polit_data.street s ON s.street_id =ds.street_id 
INNER JOIN polit_data.district d ON d.district_id =ds.district_id  
	WHERE NOT EXISTS (SELECT FROM polit_data.political_campaign_elections pce WHERE pc.political_campaign_id=pce.political_campaign_id AND e.elections_id=pce.elections_id)
	AND upper(pp.name)='APPLE' AND upper(d.district_name)='NEW_CITY' AND upper(s.street_name)='MEX' 
	UNION ALL
SELECT pc.political_campaign_id, e.elections_id,100
FROM polit_data.political_campaign pc
INNER JOIN polit_data.political_party pp ON pp.political_party_id=pc.political_campaign_id 
CROSS JOIN polit_data.elections e
INNER JOIN polit_data.registration_info  ri ON ri.registration_id=e.address_id 
INNER JOIN polit_data.district_street ds ON  ds.district_street_id =ri.district_street_id 
INNER JOIN polit_data.street s ON s.street_id =ds.street_id 
INNER JOIN polit_data.district d ON d.district_id =ds.district_id 
	WHERE NOT EXISTS (SELECT FROM polit_data.political_campaign_elections pce WHERE pc.political_campaign_id=pce.political_campaign_id AND e.elections_id=pce.elections_id)
	AND upper(pp.name)='LIBERALS' AND upper(d.district_name)='MARKET' AND upper(s.street_name)='LENINA';

INSERT INTO polit_data.campaign_volunteers(name,surname,date_of_birth,gender,roles, phone_number,political_campaign_id)
SELECT 'Maria', 'Urkis', TO_DATE('1991-04-04','YYYY-MM-DD'), 'female'::gender, 'manager', '+7564958563', pc.political_campaign_id
FROM polit_data.political_campaign pc
INNER JOIN polit_data.political_party pp ON pp.political_party_id=pc.political_campaign_id 
	WHERE NOT EXISTS (SELECT FROM polit_data.campaign_volunteers cv WHERE cv.political_campaign_id=pc.political_campaign_id)
	AND upper(pp.name)='APPLE'
	UNION ALL 
SELECT 'Oleg','Vasiliev', TO_DATE('1980-07-15','YYYY-MM-DD'), 'male'::gender, 'promoter','+6958632457', pc.political_campaign_id
FROM polit_data.political_campaign pc
INNER JOIN polit_data.political_party pp ON pp.political_party_id=pc.political_campaign_id 
	WHERE NOT EXISTS (SELECT FROM polit_data.campaign_volunteers cv WHERE cv.political_campaign_id=pc.political_campaign_id)
	AND upper(pp.name)='LIBERALS'; 

INSERT INTO polit_data.elections_campaign_volunteers (elections_id, campaign_volunteers_id, start_time, end_time)
SELECT e.elections_id, cv.campaign_volunteers_id,TO_TIMESTAMP('2010-09-01 08:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2010-09-01 18:25:00', 'YYYY-MM-DD HH24:MI:SS')
FROM polit_data.elections e
INNER JOIN polit_data.registration_info ri ON ri.registration_id =e.address_id 
INNER JOIN polit_data.district_street ds ON ds.district_street_id=ri.district_street_id
INNER JOIN polit_data.district d ON d.district_id=ds.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
CROSS JOIN polit_data.campaign_volunteers cv
INNER JOIN polit_data.political_campaign pc ON pc.political_campaign_id =cv.campaign_volunteers_id 
INNER JOIN polit_data.political_party pp ON pp.political_party_id=pc.political_campaign_id
	WHERE NOT EXISTS (SELECT FROM polit_data.elections_campaign_volunteers ecv WHERE e.elections_id=ecv.elections_id AND cv.campaign_volunteers_id=ecv.campaign_volunteers_id)
	AND upper(pp.name)='APPLE' AND upper(d.district_name)='MARKET' AND upper(s.street_name)='LENINA'
	UNION ALL 
SELECT e.elections_id, cv.campaign_volunteers_id,TO_TIMESTAMP('2012-09-01 06:55:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2012-09-01 14:10:00','YYYY-MM-DD HH24:MI:SS')
FROM polit_data.elections e
INNER JOIN polit_data.registration_info ri ON ri.registration_id =e.address_id 
INNER JOIN polit_data.district_street ds ON ds.district_street_id=ri.district_street_id
INNER JOIN polit_data.district d ON d.district_id=ds.district_id
INNER JOIN polit_data.street s ON s.street_id =ds.street_id
CROSS JOIN polit_data.campaign_volunteers cv
INNER JOIN polit_data.political_campaign pc ON pc.political_campaign_id =cv.campaign_volunteers_id 
INNER JOIN polit_data.political_party pp ON pp.political_party_id=pc.political_campaign_id
	WHERE NOT EXISTS (SELECT FROM polit_data.elections_campaign_volunteers ecv WHERE e.elections_id=ecv.elections_id AND cv.campaign_volunteers_id=ecv.campaign_volunteers_id)
	AND upper(pp.name)='LIBERALS' AND upper(d.district_name)='NEW_CITY' AND upper(s.street_name)='MEX';

INSERT INTO polit_data.events( type_of_event,number_of_spectators, number_of_mentions_on_social_networks, number_of_mentions_on_television,date_of_events)
SELECT   'online'::type_of_event, 4569,46,46, to_date('2020-04-01','yyyy-mm-dd')
WHERE NOT EXISTS (SELECT events_id  FROM polit_data.events)
UNION ALL 
SELECT   'offline'::type_of_event,12,0,2, to_date('2002-10-01','yyyy-mm-dd')
WHERE NOT EXISTS (SELECT events_id FROM polit_data.events); 					

INSERT INTO polit_data.campaign_volunteers_events (events_id , campaign_volunteers_id, start_time, end_time)
SELECT ev.events_id , cv.campaign_volunteers_id,TO_TIMESTAMP('2021-10-01 08:00:00','YYYY-MM-DD HH24:MI:SS'),TO_TIMESTAMP('2021-10-01 10:25:00','YYYY-MM-DD HH24:MI:SS')
FROM polit_data.events ev 
CROSS JOIN polit_data.campaign_volunteers cv
	WHERE NOT EXISTS (SELECT FROM polit_data.campaign_volunteers_events cve WHERE cve.campaign_volunteers_id=cv.campaign_volunteers_id AND ev.events_id=cve.events_id)
	AND ev.date_of_events= '2020-04-01' AND  upper(cv."name")= 'OLEG' AND upper(cv.surname)='VASILIEV'
	UNION ALL 
SELECT ev.events_id , cv.campaign_volunteers_id,TO_TIMESTAMP('2012-09-01 06:55:00','YYYY-MM-DD HH24:MI:SS'),  TO_TIMESTAMP('2012-09-01 14:10:00','YYYY-MM-DD HH24:MI:SS')
FROM polit_data.events ev 
CROSS JOIN polit_data.campaign_volunteers cv
WHERE NOT EXISTS (SELECT FROM polit_data.campaign_volunteers_events cve WHERE cve.campaign_volunteers_id=cv.campaign_volunteers_id AND ev.events_id=cve.events_id)
	AND ev.date_of_events= '2002-10-01' AND  upper(cv."name")= 'MARIA' AND upper(cv.surname)='URKIS';

INSERT INTO polit_data.events_campaign (events_id,political_campaign_id )
SELECT ev.events_id,pc.political_campaign_id
FROM polit_data.events ev
CROSS JOIN polit_data.political_campaign pc
INNER JOIN polit_data.political_party pp ON pp.political_party_id=pc.political_campaign_id
	WHERE NOT EXISTS (SELECT FROM polit_data.events_campaign ec WHERE  ev.events_id=ec.events_id AND  pc.political_campaign_id=ec.political_campaign_id)
	AND ev.date_of_events= '2002-10-01'  AND upper(pp."name")= 'APPLE'
UNION ALL 
SELECT ev.events_id,pc.political_campaign_id
FROM polit_data.events ev
CROSS JOIN polit_data.political_campaign pc
INNER JOIN polit_data.political_party pp ON pp.political_party_id=pc.political_campaign_id
	WHERE NOT EXISTS (SELECT FROM polit_data.events_campaign ec WHERE  ev.events_id=ec.events_id AND  pc.political_campaign_id=ec.political_campaign_id)
	AND ev.date_of_events= '2020-04-01'  AND upper(pp."name")= 'LIBERALS';



	
   -----------------ALTER----------------
ALTER TABLE polit_data.campaign_donors ADD COLUMN IF NOT EXISTS record_ts date DEFAULT CURRENT_date NOT NULL; 
ALTER TABLE polit_data.finances_income ADD COLUMN IF NOT EXISTS record_ts date DEFAULT CURRENT_date NOT NULL;
ALTER TABLE polit_data.finances_campaign_donors ADD COLUMN IF NOT EXISTS record_ts date DEFAULT CURRENT_date NOT NULL; 
ALTER TABLE polit_data.candidates ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;  
ALTER TABLE polit_data.political_party ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.political_campaign ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.street ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.city ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.district ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.district_street ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.registration_info ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.people_info ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;  
ALTER TABLE polit_data.elections ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.people_elections ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.political_campaign_elections ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.campaign_volunteers ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.elections_campaign_volunteers ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.events ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.campaign_volunteers_events  ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;
ALTER TABLE polit_data.events_campaign ADD COLUMN IF NOT EXISTS record_ts date DEFAULT current_date;




