## Introduction

A starting example for the project of the BDR course. You may base your own code on this example (or do something entirely different).


## Description

Based on the [flask tutorial example](https://github.com/pallets/flask/tree/main/examples/tutorial)

Use the pagila database seen in lab3, but with a few modifications (see [pagila-ui/sql/pagila-alter.sql])

This example is not secured, any one can authenticate without any proof of identity.


## Technologies

[Flask](https://flask.palletsprojects.com/en/stable/)
: A lightweight framework to develop web application framework. It is integrated with the [Jinja2](https://jinja.palletsprojects.com/en/stable/) template engine to generate HTML pages.

[HTMX](https://htmx.org/)
: A library that extends HTML with attributes that allow new type of interaction with the server, with no or minimal JavaScript.

[Hyperscript](https://hyperscript.org/)
: To make writing frontend interaction a joy.
: It is used to show/hide the menu bar and a modal for the pagination.

[Bulma](https://bulma.io/)
: A CSS framework.


## Features

- List stores
- List inventory of a store
- Simple log-in as a customer (with only email)
- Allow renting a film (if there is a copy available in the inventory)
- Allow returning a rented film
- Pagination


## Getting started

### Requirements

- Python 3.11 or above
- [Poetry](https://python-poetry.org/) to manage dependencies

### Installing dependencies

```sh
poetry install
```

### Preparing the database

```sh
docker compose up -d
export PAGILA_DB="postgresql://bdr:bdr@localhost:5432/bdr" 
flask --app pagila-ui init-db
```

### Running the server

```sh
export PAGILA_DB="postgresql://bdr:bdr@localhost:5432/bdr" 
flask --app pagila-ui run --debug
```
