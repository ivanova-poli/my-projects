
--All animation movies released BETWEEN 2017 and 2019 with rate more than 1, alphabetical					

SELECT f.title
FROM film f
INNER JOIN film_category fc  -
on fc.film_id =f.film_id 
WHERE fc.category_id =
					(SELECT c.category_id 
					FROM category c
					WHERE upper(name)='ANIMATION')			
AND f.release_year BETWEEN 2017 and 2019
AND f.rental_rate >1
ORDER BY f.title ;

--The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)

SELECT concat(a.address,' ', a.address2) AS full_address, 
		SUM(p.amount) AS revenue
FROM payment p  							
INNER JOIN rental r							
ON r.rental_id=p.rental_id 					
INNER JOIN inventory i
ON i.inventory_id=r.inventory_id 
INNER JOIN store s
ON s.store_id=i.store_id 
INNER JOIN address a
ON a.address_id=s.address_id 
WHERE p.payment_date>'2017-03-31'
GROUP BY a.address_id;

--Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in DESCending order)

SELECT first_name, last_name, 
		COUNT(fa.film_id) as number_of_movies
FROM actor a 
INNER JOIN film_actor fa 		
ON a.actor_id =fa.actor_id 
INNER JOIN film f 
ON f.film_id =fa.film_id 			
WHERE f.release_year>2015
GROUP BY a.actor_id  
ORDER BY number_of_movies DESC, a.actor_id ASC
LIMIT 5;

--Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies)

SELECT f.release_year, 
	COUNT(CASE WHEN upper(c.name) = 'DRAMA' THEN 1 END) AS number_of_drama_movies,    
    COUNT(CASE WHEN upper(c.name) = 'TRAVEL' THEN 1 END) AS number_of_travel_movies,
    COUNT(CASE WHEN upper(c.name) = 'DOCUMENTARY' THEN 1 END) AS number_of_documentary_movies
FROM film f 
INNER JOIN film_category fc on fc.film_id=f.film_id 			
INNER JOIN category c on fc.category_id=c.category_id			
GROUP BY f.release_year 
ORDER BY f.release_year DESC;

/*Who were the top revenue-generating staff members in 2017? 
 Please indicate which store the employee worked in. If he changed stores during 2017, indicate each store. 
 * (assumption: if staff processed the payment then he works in the same store)*/

	WITH revenue as(
	SELECT s.store_id, s.staff_id, sum(p.amount) AS revenue,
	ROW_NUMBER() OVER (PARTITION BY s.store_id ORDER BY sum(p.amount) DESC) AS rating
	FROM staff s
	INNER JOIN payment p ON p.staff_id =s.staff_id 
	WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
	GROUP BY s.store_id, s.staff_id
	)
SELECT DISTINCT s.first_name || ' '|| s.last_name AS name, 
 s.store_id , max(r.revenue) 
FROM staff s
INNER JOIN revenue r ON s.staff_id =r.staff_id
WHERE r.rating =1
GROUP BY  s.store_id, name
ORDER BY max desc;

/*Which 5 movies were rented more than others, and what's the expected age of the audience for these movies? 
To determine expected age please use 'Motion Picture association film rating system*/

SELECT f.title,  
		COUNT(r.rental_id) AS number_of_rented,
		CASE 
			WHEN f.rating = 'PG' THEN 'Some material may not be suitable for children'
			WHEN f.rating = 'R' THEN 'Under 17 requires accompanying parent or adult guardian'
			WHEN f.rating = 'NC-17' THEN 'No one 17 and under admitted'
			WHEN f.rating = 'PG-13' THEN 'Some material may be inappropriate for children under 13'
			WHEN f.rating = 'G' THEN 'All ages admitted'
		END AS age_rating		
FROM film f 
INNER JOIN inventory i   --this table contains information about what inventory number each copy of the film has
ON f.film_id =i.film_id 
INNER JOIN rental r 		--this table contains information about how many time each inventory number was rented
ON i.inventory_id =r.inventory_id  
GROUP BY f.film_id 
ORDER BY COUNT(r.rental_id) DESC, f.film_id ASC
LIMIT 5;

/*Which actors/actresses didn't act for a longer period of time than the others? */

WITH gap_table AS 
(SELECT a.first_name||' '|| a.last_name AS full_name, 
			(EXTRACT(year FROM current_date)-MAX(f.release_year)) AS gap_year 
		FROM film f
		INNER JOIN  film_actor fa 
		ON fa.film_id=f.film_id
		INNER JOIN actor a		
		ON a.actor_id=fa.actor_id
		GROUP BY a.actor_id 
		)

SELECT full_name, gap_year
FROM  gap_table
WHERE gap_year IN (SELECT max(gap_year) FROM gap_table);

--Top-3 most selling movie categories of all time and total dvd rental income for each category. Only consider dvd rental customers from the USA.

WITH table_usa AS 
(
SELECT c.customer_id
FROM customer c 
INNER JOIN address a ON a. address_id =c.address_id 
INNER JOIN city ON a.city_id=city.city_id
INNER JOIN country c2 ON city.country_id=c2.country_id
WHERE UPPER(c2.country) = 'UNITED STATES'
)

SELECT ca.name, sum(p.amount) AS revenue 
FROM category ca
INNER JOIN film_category fc ON fc.category_id =ca.category_id
INNER JOIN inventory i ON fc.film_id=i.film_id
INNER JOIN rental r ON i.inventory_id=r.inventory_id
INNER JOIN payment p ON r.rental_id=p.rental_id
WHERE r.customer_id IN (SELECT customer_id FROM table_usa)
GROUP BY ca.category_id
ORDER BY revenue DESC
LIMIT 3;

--For each client, display a list of horrors that he had ever rented (in one column, separated by commas), and the amount of money that he paid for it
SELECT c2.customer_id,
c2.first_name ||' '|| c2.last_name AS customer_name,
	string_agg(f.title, ', ') AS rented_horor_films, 
	count(f.title) AS number_of_films,				
	sum(p.amount) AS spent_money
FROM film f 
INNER JOIN film_category fc ON fc.film_id =f.film_id		
INNER JOIN category c ON c.category_id=fc.category_id			
INNER JOIN inventory i ON fc.film_id=i.film_id
INNER JOIN rental r ON i.inventory_id=r.inventory_id
INNER JOIN payment p ON p.rental_id =r.rental_id 
INNER JOIN customer c2 ON p.customer_id =c2.customer_id 
WHERE upper(c.name) like '%HORROR%'
GROUP BY c2.customer_id
ORDER BY spent_money DESC;

--DML

--Choose your top-3 favorite movies and add them to the 'film' table. Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.

INSERT INTO film_actor (actor_id, film_id) 			
SELECT a.actor_id, f.film_id					
FROM film f											
CROSS JOIN actor a
	WHERE NOT EXISTS 
	(SELECT FROM film_actor fa	WHERE fa.actor_id=a.actor_id AND fa.film_id=f.film_id ) 
AND UPPER(f.title) = 'FORSAG' AND upper(first_name) = 'DOMINIC' AND upper(last_name) ='TORRETO';

INSERT INTO film (title, release_year,language_id ,rental_duration, rental_rate) 
SELECT 'Shrek', 2008, l.language_id, 1, 4.99	
FROM language l 
WHERE upper(l.name)='ENGLISH'
AND NOT EXISTS 
	(SELECT FROM film f WHERE UPPER(f.title)='SHREK') 			
UNION ALL 
SELECT 'Forsag', 2010, l.language_id, 2,9.99
FROM language l 
WHERE upper(l.name)='FRENCH'
	AND NOT EXISTS 
	(SELECT FROM film WHERE upper(title)='FORSAG')
UNION ALL 
SELECT 'Twilight', 2005, l.language_id, 3, 19.99
FROM language l 
WHERE upper(l.name)='GERMAN'
	AND NOT EXISTS 
	(SELECT 'Twilight' FROM film WHERE title='Twilight');


--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables.
INSERT INTO actor(first_name, last_name)
SELECT 'Will', 'Smith'				
	WHERE NOT EXISTS 					
	(SELECT FROM actor WHERE first_name='Will' and last_name='Smith');
--(he is not here, so next we add this actor to the films where he is starring)

INSERT INTO film_actor (actor_id, film_id)  							
SELECT a.actor_id, f.film_id											
FROM film f
CROSS join actor a 														
	WHERE NOT EXISTS (SELECT FROM film_actor fa WHERE fa.actor_id=a.actor_id AND fa.film_id=f.film_id)
AND upper(f.title)='SHREK' AND upper(a.first_name)='WILL' and upper(a.last_name)='SMITH';

INSERT INTO actor (first_name,last_name)
SELECT 'Dominic', 'Torreto'
	WHERE NOT EXISTS 
	(SELECT 'Dominic', 'Torreto' FROM actor WHERE upper(first_name) = 'DOMINIC' AND upper(last_name) ='TORRETO')
UNION ALL
SELECT 'Paul', 'Uoker'
	WHERE NOT EXISTS 
	(SELECT 'Paul', 'Uoker' FROM actor WHERE upper(first_name) = 'PAUL' AND upper(last_name) ='UOKER');

INSERT INTO film_actor (actor_id, film_id) 			
SELECT a.actor_id, f.film_id					
FROM film f											
CROSS JOIN actor a
	WHERE NOT EXISTS 
	(SELECT FROM film_actor fa	WHERE fa.actor_id=a.actor_id AND fa.film_id=f.film_id ) 
AND UPPER(f.title) = 'FORSAG' AND upper(first_name) = 'DOMINIC' AND upper(last_name) ='TORRETO'
UNION ALL
SELECT a.actor_id, f.film_id 
FROM film f
CROSS JOIN actor a 
	WHERE NOT EXISTS 
	(SELECT FROM film_actor fa WHERE fa.actor_id=a.actor_id AND fa.film_id=f.film_id ) 
AND upper(f.title)='FORSAG' AND upper(first_name) = 'PAUL' AND upper(last_name) ='UOKER';


INSERT INTO actor (first_name, last_name)
SELECT 'Rob', 'Patison'
	WHERE NOT EXISTS (SELECT 'Rob', 'Patison' FROM actor  WHERE upper(first_name) = 'ROB' AND upper(last_name) ='PATISON')
UNION ALL 
SELECT 'Filipp', 'kirkorov'
	WHERE NOT EXISTS (SELECT 'Filipp', 'kirkorov' FROM actor WHERE upper(first_name)= 'FILIPP' AND upper(last_name)='KIRKOROV')
	UNION ALL 
SELECT 'Bella', 'Swon'
	WHERE NOT EXISTS 
(SELECT 'Bella', 'Swon' FROM actor WHERE upper(first_name)='BELLA' AND upper(last_name)='SWON');

INSERT INTO film_actor (actor_id, film_id)							
SELECT  a.actor_id, f.film_id
FROM film f
CROSS JOIN actor a 
	WHERE NOT EXISTS 
	(SELECT FROM film_actor fa WHERE f.film_id =fa.film_id AND a.actor_id =fa.actor_id)
AND  upper(first_name)='BELLA' AND upper(last_name)='SWON' AND upper(f.title)='TWILIGHT'
UNION ALL 							
SELECT  a.actor_id, f.film_id
FROM film f
CROSS JOIN actor a 
	WHERE NOT EXISTS 
	(SELECT FROM film_actor fa WHERE f.film_id =fa.film_id AND a.actor_id =fa.actor_id)
AND  upper(first_name)= 'FILIPP' AND upper(last_name)='KIRKOROV' AND upper(f.title)='TWILIGHT'
UNION ALL 					
SELECT  a.actor_id, f.film_id
FROM film f
CROSS JOIN actor a 
	WHERE NOT EXISTS 
	(SELECT FROM film_actor fa WHERE f.film_id =fa.film_id AND a.actor_id =fa.actor_id)
AND  upper(first_name) = 'ROB' AND upper(last_name) ='PATISON' AND upper(f.title)='TWILIGHT';

--Add your favorite movies to any store's inventory.

INSERT INTO inventory (film_id, store_id)  
SELECT f.film_id, s.store_id
FROM film f
CROSS JOIN store s
INNER JOIN address a ON a.address_id=s.address_id 
	WHERE NOT EXISTS 
	(SELECT FROM inventory i WHERE f.film_id=i.film_id AND  s.store_id=i.store_id)
AND (
	(upper(f.title)='SHREK' AND a.address ='47 MySakila Drive1') OR 
	(upper(f.title)='SHREK' AND a.address ='28 MySQL Boulevard2') OR 
	(upper(f.title)='TWILIGHT' AND a.address='47 MySakila Drive1') OR 
	(upper(f.title)='FORSAG' AND a.address ='28 MySQL Boulevard2') OR 
	(upper(f.title)='FORSAG' AND a.address ='28 MySQL Boulevard2'))
;
/*Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours (first name, last name, address, etc.)*/

UPDATE customer 
SET first_name ='Polina',
	last_name ='Ivanova',
	address_id = (SELECT address_id FROM address  WHERE address='1560 Jelets Boulevard' AND postal_code='77777')  
	WHERE NOT EXISTS
	(SELECT FROM customer c 
					WHERE customer_id IN (SELECT customer_id
					FROM payment p 
					GROUP BY customer_id
					HAVING count(payment_id)>43
					ORDER BY count(payment_id) DESC
					LIMIT 5));

--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'

DELETE FROM payment  
WHERE customer_id =
			(SELECT customer_id
			FROM customer
			WHERE upper(first_name)='POLINA' AND upper(last_name)='IVANOVA');

--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
/*(Note: to insert the payment_date into the table payment, add records for the first half of 2017)*/
		
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id) 			
SELECT '2017-01-05', i.inventory_id, c.customer_id,st.staff_id 							
FROM inventory i 
JOIN film f ON f.film_id =i.film_id 
JOIN staff st ON i.store_id =st.store_id 
CROSS JOIN customer c 
	WHERE NOT EXISTS 
	(SELECT FROM rental r WHERE i.inventory_id=r.inventory_id AND  c.customer_id=r.customer_id AND r.staff_id=st.staff_id )
AND upper(f.title)='TWILIGHT' AND upper(c.first_name)='POLINA' AND upper(c.last_name)='IVANOVA' AND upper(st.email)='Mike.Hillyer@sakilastaff.com';

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date) 
SELECT c.customer_id, st.staff_id ,r.rental_id, 5,'2017-02-05'
FROM rental r
JOIN customer c ON c.customer_id  =r.customer_id 
JOIN inventory i ON i.inventory_id =r.inventory_id 
JOIN staff st ON i.store_id =st.store_id 
JOIN film f ON i.film_id = f.film_id 
	WHERE NOT EXISTS (SELECT FROM payment p WHERE c.customer_id=p.customer_id AND r.rental_id=p.rental_id AND st.staff_id=p.staff_id)
AND upper(f.title)='TWILIGHT' AND upper(c.first_name)='POLINA' AND upper(c.last_name)='IVANOVA' AND upper(st.email)='Mike.Hillyer@sakilastaff.com';

/*Create a view
 that shows the film category and total sales revenue for the current quarter and year. 
Note: when the next quarter begins, it will be considered as the current quarter.*/

CREATE OR REPLACE VIEW  sales_revenue_by_category_qtr AS 
SELECT c.name, sum(p.amount) AS revenue 
FROM category c 
INNER JOIN film_category fc ON fc.category_id=c.category_id
inner JOIN inventory i ON i.film_id=fc.film_id
INNER JOIN rental r ON r.inventory_id=i.inventory_id
INNER JOIN payment p ON p.rental_id=r.rental_id
WHERE extract(quarter FROM p.payment_date) = extract(quarter FROM current_date) AND extract(YEAR FROM p.payment_date) = extract(YEAR FROM current_date)
GROUP BY  c.category_id, c.name
-- The view should only display categories with at least one sale in the current quarter
HAVING sum(p.amount)>0;


/* Create a query language functions
that accepts one parameter representing the current quarter and year and returns the same result as the view.*/
 
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr (IN put_year date DEFAULT current_date)
RETURNS TABLE (categore_name TEXT,
				revenue float)
AS $$
SELECT c.name, sum(p.amount) AS revenue 
FROM category c 
INNER JOIN film_category fc ON fc.category_id=c.category_id
inner JOIN inventory i ON i.film_id=fc.film_id
INNER JOIN rental r ON r.inventory_id=i.inventory_id
INNER JOIN payment p ON p.rental_id=r.rental_id
WHERE extract(YEAR FROM p.payment_date) = extract(YEAR FROM put_year) AND extract(quarter FROM p.payment_date) = EXTRACT(quarter FROM put_year) 
OR put_year IS NULL 
GROUP BY c.category_id, c.name
HAVING sum(p.amount)>0
$$
LANGUAGE SQL;

SELECT * FROM get_sales_revenue_by_category_qtr(to_date('2017-05-05','yyyy-mm-dd'));

/*Create procedure language functions
 that takes a country as an input parameter and returns the most popular film in that specific country.*/


CREATE OR REPLACE FUNCTION  most_popular_films_by_countries(i_country TEXT[])
RETURNS TABLE (country text, 
				title text, 
				rating film.rating%type, 
				"language" "language".name%type, 
				"length" int2, 
				release_year int) 
language plpgsql
as
$$
DECLARE 
country_name text;
 BEGIN
	FOR country_name IN SELECT unnest(i_country) LOOP 
		RETURN query
		WITH film_table AS (
		SELECT c.country, f.title, f.rating, l.name, f.length, f.release_year::integer, count(r.rental_id) AS rental_amount
		FROM country c
		INNER JOIN city ci ON ci.country_id=c.country_id
		INNER JOIN address a ON a.city_id=ci.city_id
		INNER JOIN customer cu ON cu.address_id=a.address_id 
		INNER JOIN rental r ON r.customer_id=cu.customer_id 
		INNER JOIN inventory i ON r.inventory_id=i.inventory_id    
		INNER JOIN film f ON f.film_id=i.film_id
		INNER JOIN "language" l ON l.language_id=f.language_id
		WHERE upper(c.country)=upper(country_name) 
		GROUP BY c.country_id,f.title, f.rating, l.name, f.length, f.release_year::integer)
		
		SELECT ft.country, ft.title, ft.rating, ft.name, ft.length, ft.release_year::integer
		FROM film_table ft
        WHERE ft.rental_amount= 
        			(SELECT max(rental_amount) 
        			FROM       
					film_table ft);
	IF NOT exists(SELECT c.country
				FROM country c
				WHERE upper(c.country)= upper(country_name))
	THEN RAISE NOTICE 'Country % is not found', country_name;
	END IF;
		END LOOP;
END;
$$;

SELECT * FROM most_popular_films_by_countries(ARRAY['Afgha','Brazil','United States']);


/* Create procedure language functions
that generates a list of movies available in stock based on a partial title match. 
The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, return a message indicating that it was not found.*/

CREATE OR REPLACE FUNCTION films_in_stock_by_title(input_title varchar) 
RETURNS TABLE (row_num int,
				film_title TEXT,
				"language" "language".name%TYPE,
				customer_name TEXT, 
				rental_date rental.rental_date%type)
LANGUAGE plpgsql AS $$ 
DECLARE
record_found record;
counter int:=0;
BEGIN 

	FOR record_found IN SELECT  DISTINCT ON (f.title) f.title , l.name, cu.first_name || ' '|| cu.last_name AS customer_name , r.rental_date
	FROM customer cu  
	INNER JOIN rental r ON r.customer_id=cu.customer_id 
	INNER JOIN inventory i ON r.inventory_id=i.inventory_id    
	INNER JOIN film f ON f.film_id=i.film_id
	INNER JOIN "language" l ON l.language_id=f.language_id		
	WHERE  f.title ILIKE input_title 
	ORDER BY f.title, r.rental_date DESC 
	LOOP
		counter:=counter+1;
		row_num:=counter;
		film_title:= record_found.title;
		"language":= record_found.name;
		customer_name:= record_found.customer_name  ;
		rental_date:= record_found.rental_date;
	RETURN NEXT ;	
	END LOOP;
		IF NOT FOUND THEN 
     RAISE NOTICE  'Film % is not found', input_title;
   END IF;
end;
$$

select * from films_in_stock_by_title('%lodfsf%');

/*Create procedure language functions   
Create a procedure language function called 'new_movie' that takes a movie 
title as a parameter and inserts a new movie with the given title in the film table. 
The release year and language are optional and by default should be current year and Klingon respectively. */

CREATE OR REPLACE FUNCTION new_movie (
	 
	movie_title TEXT,
	p_release_year YEAR DEFAULT EXTRACT(YEAR FROM current_date),
	language_name TEXT DEFAULT 'Klingon'
	)
	RETURNS SETOF film 
	LANGUAGE plpgsql
	AS 
	$$
	DECLARE 
	
	v_rental_rate film.rental_rate%TYPE = 4.99;
	v_rental_duration film.rental_duration%TYPE=3;
	v_replacement_cost film.replacement_cost%TYPE= 19.99;
	v_language_id int;
	v_return film%rowtype;
		
	BEGIN 
		
	IF (SELECT language_id
		FROM "language" l
		WHERE upper(l.name)=upper(language_name))
	IS NULL THEN 
	INSERT INTO "language" ("name")
	VALUES (language_name);
	END IF;

	SELECT language_id
	INTO v_language_id
	FROM "language" l 
	WHERE upper(l.name)=upper(language_name);

INSERT INTO film (title, release_year, language_id, rental_duration, rental_rate, replacement_cost)
VALUES (movie_title, p_release_year, v_language_id,v_rental_duration,v_rental_rate,v_replacement_cost )	
EXCEPT 
SELECT title, release_year, language_id, rental_duration, rental_rate, replacement_cost FROM film 
RETURNING * INTO v_return;
RETURN NEXT v_return;

IF NOT FOUND THEN RAISE NOTICE 'film % already exists', movie_title;
END IF;
	END;
$$;
	
SELECT * FROM new_movie('Moloko',2011,'fgfhjftjrrtjr')

/* Create one function that reports all information for a particular client and timeframe
Customer's name, surname and email address;
Number of films rented during specified timeframe;
Comma-separated list of rented films at the end of specified time period;
Total number of payments made during specified time period;
Total amount paid during specified time period;
Function's input arguments: client_id, left_boundary, right_boundary.
*/

CREATE OR REPLACE FUNCTION get_client_info(client_id INT, left_boundary DATE, right_boundary DATE)
RETURNS TABLE (metric_name TEXT, metric_value text) 
LANGUAGE plpgsql
AS $$
DECLARE 
p_client_info TEXT;
p_film_amount int;
p_payment int;
p_payment_amount float;
p_films TEXT;

BEGIN
	
    SELECT c.first_name || ' '||c.last_name || ', '||c.email 
    INTO p_client_info
    FROM customer c
    WHERE c.customer_id = client_id;
   
   SELECT count(r.rental_id)
   INTO p_film_amount
   FROM rental r
   WHERE r.customer_id = client_id AND r.rental_date BETWEEN left_boundary AND right_boundary;
   
   SELECT string_agg(DISTINCT f.title, ',')::text 
   INTO p_films
   FROM film f 
   INNER JOIN inventory i ON i.film_id=f.film_id
   INNER JOIN rental r ON r.inventory_id=i.inventory_id
   WHERE r.customer_id = client_id AND r.rental_date BETWEEN left_boundary AND right_boundary;
  
   SELECT count(p.payment_id)
   INTO p_payment 
   FROM payment p 
   WHERE p.customer_id = client_id AND p.payment_date  BETWEEN left_boundary AND right_boundary;
   
   SELECT  sum(p.amount)
   INTO p_payment_amount
   FROM payment p 
   WHERE p.customer_id = client_id AND p.payment_date  BETWEEN left_boundary AND right_boundary
   ;
   IF (left_boundary >=right_boundary) THEN 
   RAISE NOTICE 'incorrect period';
  	END IF;
  RETURN QUERY 
  
  SELECT 'customer''s info', COALESCE (p_client_info, 'customer id is not found')
  UNION ALL
  SELECT 'num. of films rented', CASE WHEN p_client_info IS NULL THEN 'n/a' ELSE cast(p_film_amount AS text) END 
  UNION ALL
  SELECT 'rented films'' titles', COALESCE (p_films, 'n/a')
  UNION ALL
  SELECT 'num of payments', CASE WHEN p_client_info IS NULL THEN 'n/a' ELSE cast(p_payment  AS text) END 
  UNION ALL
  SELECT 'payments'' amount', CASE WHEN p_client_info IS NULL THEN 'n/a' ELSE cast(p_payment_amount  AS text) END ;
  
	END;
$$ ;
	
SELECT * FROM  get_client_info (1545456, to_date('2000-02-12 00:00:00', 'yyyy-mm-dd HH24:MI:SS'), to_date('2020-02-12 00:00:00', 'yyyy-mm-dd HH24:MI:SS'));












