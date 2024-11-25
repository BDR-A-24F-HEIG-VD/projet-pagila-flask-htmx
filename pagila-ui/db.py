import psycopg
from psycopg.rows import namedtuple_row

import click
from flask import Flask, current_app
from flask import g


def get_db():
    """Connect to the application's configured database. The connection
    is unique for each request and will be reused if this is called
    again.
    """
    if "db" not in g:
        g.db = psycopg.connect(
            current_app.config["DATABASE"], row_factory=namedtuple_row
        )

    return g.db


def close_db(e=None):
    """If this request connected to the database, close the
    connection. If there was no error commit the connection.
    """
    db: psycopg.Connection = g.pop("db", None)

    if db is not None:
        if e is None:
            db.commit()
        db.close()


def init_db():
    """Clear existing data and create new tables."""
    sql_scripts = [
        "pagila-schema.sql",
        "pagila-import.sql",
        "pagila-alter.sql",
    ]
    db = get_db()
    for script in sql_scripts:
        path = f"sql/{script}"
        with current_app.open_resource(path) as f:
            click.echo(f"Executing script: {path}")
            db.execute(f.read().decode("utf8"))


@click.command("init-db")
def init_db_command():
    """Clear existing data and create new tables."""
    init_db()
    click.echo("Initialized the database.")


def init_app(app: Flask):
    """Register database functions with the Flask app. This is called by
    the application factory.
    """
    app.teardown_appcontext(close_db)
    app.cli.add_command(init_db_command)
