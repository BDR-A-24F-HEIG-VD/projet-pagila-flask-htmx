-- A rental with a null staff_id is created by the web self-serve service.
alter table pagila.rental
    alter column staff_id drop not null;

-- A customer can be uniquely identified by it's email.
alter table pagila.customer
         add constraint customer_email
             unique (email);