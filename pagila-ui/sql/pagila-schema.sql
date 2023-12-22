DROP SCHEMA IF EXISTS pagila CASCADE;
CREATE SCHEMA pagila;
COMMENT ON SCHEMA pagila IS 'Labo 3 and 4';


SET search_path = pagila;

CREATE DOMAIN year AS INTEGER
	CONSTRAINT year_check CHECK (((VALUE >= 1901) AND (VALUE <= 2155)));

CREATE TYPE mpaa_rating AS ENUM (
    'G',
    'PG',
    'PG-13',
    'R',
    'NC-17'
);

CREATE TYPE film_features AS ENUM (
    'Trailers',
    'Commentaries',
    'Deleted Scenes',
    'Behind the Scenes'
);

--
-- Table structure for table `actor`
--

CREATE TABLE actor (
    actor_id SMALLSERIAL PRIMARY KEY,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);
CREATE INDEX idx_actor_last_name ON actor (last_name);

--
-- Table structure for table `address`
--

CREATE TABLE address (
    address_id SMALLSERIAL PRIMARY KEY,
    address VARCHAR(50) NOT NULL,
    address2 VARCHAR(50),
    district VARCHAR(20) NOT NULL,
    city_id SMALLINT NOT NULL,
    postal_code VARCHAR(10),
    phone TEXT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);
CREATE INDEX idx_fk_city_id ON address (city_id);

--
-- Table structure for table `category`
--

CREATE TABLE category (
    category_id SMALLSERIAL PRIMARY KEY,
    name VARCHAR(25) NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

--
-- Table structure for table `city`
--

CREATE TABLE city (
    city_id SMALLSERIAL PRIMARY KEY,
    city VARCHAR(50) NOT NULL,
    country_id SMALLINT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);
CREATE INDEX idx_fk_country_id ON city (country_id);

--
-- Table structure for table `country`
--

CREATE TABLE country (
    country_id SMALLSERIAL PRIMARY KEY,
    country VARCHAR(50) NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

--
-- Table structure for table `customer`
--

CREATE TABLE customer (
    customer_id SMALLSERIAL PRIMARY KEY,
    store_id SMALLINT NOT NULL,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    email VARCHAR(50),
    address_id SMALLINT NOT NULL,
    active BOOLEAN DEFAULT true NOT NULL,
    create_date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now()
);
CREATE INDEX idx_fk_address_id ON customer (address_id);
CREATE INDEX idx_fk_store_id ON customer (store_id);
CREATE INDEX idx_last_name ON customer (last_name);

--
-- Table structure for table `film`
--

CREATE TABLE film (
    film_id SMALLSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    release_year YEAR,
    language_id SMALLINT NOT NULL,
    original_language_id SMALLINT,
    rental_duration SMALLINT DEFAULT 3 NOT NULL,
    rental_rate NUMERIC(4,2) DEFAULT 4.99 NOT NULL,
    length SMALLINT,
    replacement_cost NUMERIC(5,2) DEFAULT 19.99 NOT NULL,
    rating mpaa_rating DEFAULT 'G'::mpaa_rating,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    special_features film_features[],
    fulltext TSVECTOR NOT NULL
);
CREATE INDEX film_fulltext_idx ON film USING gist (fulltext);
CREATE INDEX idx_fk_language_id ON film (language_id);
CREATE INDEX idx_fk_original_language_id ON film (original_language_id);
CREATE INDEX idx_title ON film (title);

--
-- Table structure for table `film_actor`
--

CREATE TABLE film_actor (
    actor_id SMALLINT NOT NULL,
    film_id SMALLINT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);
CREATE INDEX idx_fk_film_id ON film_actor (film_id);

--
-- Table structure for table `film_category`
--

CREATE TABLE film_category (
    film_id SMALLINT NOT NULL,
    category_id SMALLINT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY(film_id, category_id)
);

--
-- Table structure for table `inventory`
--

CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    film_id SMALLINT NOT NULL,
    store_id SMALLINT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);
CREATE INDEX idx_store_id_film_id ON inventory (store_id, film_id);

--
-- Table structure for table `language`
--

CREATE TABLE language (
    language_id SMALLSERIAL PRIMARY KEY,
    name CHARACTER(20) NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

--
-- Table structure for table `payment`
--

CREATE TABLE payment (
    payment_id SMALLSERIAL PRIMARY KEY,
    customer_id SMALLINT NOT NULL,
    staff_id SMALLINT NOT NULL,
    rental_id SMALLINT NOT NULL,
    amount NUMERIC(5,2) NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_fk_customer_id ON payment (customer_id);
CREATE INDEX idx_fk_payment_customer_id ON payment (customer_id);
CREATE INDEX idx_fk_payment_staff_id ON payment (staff_id);
CREATE INDEX idx_fk_staff_id ON payment (staff_id);

--
-- Table structure for table `rental`
--

CREATE TABLE rental (
    rental_id SERIAL PRIMARY KEY ,
    rental_date TIMESTAMP WITH TIME ZONE NOT NULL,
    inventory_id INTEGER NOT NULL,
    customer_id SMALLINT NOT NULL,
    return_date TIMESTAMP WITH TIME ZONE,
    staff_id SMALLINT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);
CREATE INDEX idx_fk_inventory_id ON rental (inventory_id);
CREATE UNIQUE INDEX idx_unq_rental_rental_date_inventory_id_customer_id ON rental (rental_date, inventory_id, customer_id);

--
-- Table structure for table `staff`
--

CREATE TABLE staff (
    staff_id SMALLSERIAL PRIMARY KEY,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    address_id SMALLINT NOT NULL,
    email VARCHAR(50),
    store_id SMALLINT NOT NULL,
    active BOOLEAN DEFAULT true NOT NULL,
    username VARCHAR(16) NOT NULL,
    password VARCHAR(40),
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    picture BYTEA
);

--
-- Table structure for table `store`
--

CREATE TABLE store (
    store_id SMALLSERIAL PRIMARY KEY ,
    manager_staff_id SMALLINT NOT NULL,
    address_id SMALLINT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);
CREATE UNIQUE INDEX idx_unq_manager_staff_id ON store (manager_staff_id);

--
-- Foreign keys
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_city_id_fkey FOREIGN KEY (city_id) REFERENCES city(city_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY city
    ADD CONSTRAINT city_country_id_fkey FOREIGN KEY (country_id) REFERENCES country(country_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_address_id_fkey FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_store_id_fkey FOREIGN KEY (store_id) REFERENCES store(store_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY film_actor
    ADD CONSTRAINT film_actor_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES actor(actor_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY film_actor
    ADD CONSTRAINT film_actor_film_id_fkey FOREIGN KEY (film_id) REFERENCES film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY film_category
    ADD CONSTRAINT film_category_category_id_fkey FOREIGN KEY (category_id) REFERENCES category(category_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY film_category
    ADD CONSTRAINT film_category_film_id_fkey FOREIGN KEY (film_id) REFERENCES film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY film
    ADD CONSTRAINT film_language_id_fkey FOREIGN KEY (language_id) REFERENCES language(language_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY film
    ADD CONSTRAINT film_original_language_id_fkey FOREIGN KEY (original_language_id) REFERENCES language(language_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_film_id_fkey FOREIGN KEY (film_id) REFERENCES film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_store_id_fkey FOREIGN KEY (store_id) REFERENCES store(store_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY rental
    ADD CONSTRAINT rental_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY rental
    ADD CONSTRAINT rental_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY rental
    ADD CONSTRAINT rental_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY staff
    ADD CONSTRAINT staff_address_id_fkey FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY staff
    ADD CONSTRAINT staff_store_id_fkey FOREIGN KEY (store_id) REFERENCES store(store_id);
ALTER TABLE ONLY store
    ADD CONSTRAINT store_address_id_fkey FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE payment
    ADD FOREIGN KEY(customer_id) REFERENCES customer(customer_id),
    ADD FOREIGN KEY(staff_id) REFERENCES staff(staff_id),
    ADD FOREIGN KEY(rental_id) REFERENCES rental(rental_id);
