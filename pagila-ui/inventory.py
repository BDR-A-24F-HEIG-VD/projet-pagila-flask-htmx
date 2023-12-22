from flask import Blueprint
from flask import flash
from flask import g
from flask import redirect
from flask import render_template
from jinja2_fragments.flask import render_block
from flask import request
from flask import url_for
from werkzeug.exceptions import abort
from psycopg import sql

from .auth import login_required
from .db import get_db
from .utils import Pagination, UrlForParams

bp = Blueprint("inventory", __name__)


@bp.route("/")
def index():
    """Show all the stores."""
    db = get_db()
    stores = db.execute(
        """
        SELECT st.store_id
            , ad.address
            , ad.postal_code
            , ci.city
            , co.country
        FROM pagila.store st
        INNER JOIN pagila.address ad USING (address_id)
        INNER JOIN pagila.city ci USING (city_id)
        INNER JOIN pagila.country co USING (country_id)
        """).fetchall()
    return render_template("inventory/index.html", stores=stores)

@bp.route("/<int:store_id>/films")
def films(store_id):
    """Show the inventory of the given store, if a customer is logged
    in, show the rental status of each film.

    Allows pagination.
    """
    per_page = 25
    page_param = "p"
    args = request.args
    page = args.get(page_param, 1, type=int)

    cur = get_films(
        dict(
            customer_id=g.customer.customer_id if g.customer else None,
            store_id=store_id,
        ),
        condition=sql.SQL("i.store_id = %(store_id)s"), 
    )

    # Set pagination
    offset = (page - 1) * per_page
    pagination = Pagination(
        per_page=per_page,
        page_param=page_param,
        total_count=cur.rowcount,
        offset=offset,
        url_for_params=UrlForParams('inventory.films', kwargs=dict(store_id=store_id))
    )
    try:
        cur.scroll(offset)
    except:
        flash(f"Page {page} doesn't exists", category="warning")
        # Show first page
        pagination.offset=0
        cur.scroll(0)

    films = cur.fetchmany(per_page)
    return render_template("inventory/films.html", store_id=store_id, films=films, pagination=pagination)

def get_films(params, condition: sql.SQL = sql.SQL("TRUE"), order: sql.SQL = sql.SQL("f.title ASC")):
    """Retrieve films with information about the rental status
    
    The caller can filter the result using a given condition and sort 
    the result using a given order.
    """
    db = get_db()
    q = sql.SQL("""
        SELECT min(i.inventory_id)
            , f.film_id
            , f.title
            , f.description
            , f.release_year
            , f.length
            , COUNT(r.rental_id) AS nb_rented
            , COUNT(i.inventory_id) AS nb_copy
            , MIN(r.rental_id) FILTER (WHERE r.customer_id = %(customer_id)s) AS rental_id
        FROM pagila.inventory i
        INNER JOIN pagila.film f USING (film_id)
        LEFT JOIN pagila.rental r 
            ON i.inventory_id = r.inventory_id 
            AND r.return_date IS NULL
        WHERE {condition}
        GROUP BY f.film_id
        ORDER BY {order}
        """).format(
            condition=condition,
            order=order,
        )
    return db.execute(q, params)

def get_film(store_id, film_id):
    """Retrieve a given film with information about the rental status 
    in a given store"""
    return get_films(
        dict(
            customer_id=g.customer.customer_id if g.customer else None,
            store_id=store_id,
            film_id=film_id
        ),
        condition=sql.SQL("i.store_id = %(store_id)s AND i.film_id = %(film_id)s"),
    ).fetchone()


@login_required
@bp.route("/<int:store_id>/films/<int:film_id>/rentals", methods=("POST",))
def rent(store_id, film_id):
    db = get_db()
    rental = db.execute(
        """
        INSERT INTO pagila.rental (rental_date, inventory_id, customer_id)
        SELECT now(), MIN(inventory_id), %(customer_id)s
        FROM pagila.inventory
        LEFT JOIN pagila.rental USING (inventory_id)
        WHERE store_id = %(store_id)s 
            AND film_id = %(film_id)s 
            AND (rental_id IS NULL OR return_date IS NOT NULL)
        RETURNING rental_id
        """, dict(
            customer_id=g.customer.customer_id if g.customer else None,
            store_id=store_id,
            film_id=film_id,
        )).fetchone()
    error = None
    
    if not rental:
        error = "Couldn't rent the movie"

    if error is not None:
        flash(error, "danger")        

    film = get_film(store_id, film_id)
    
    return render_block("inventory/films.html", 'film_entry', store_id=store_id, film=film)
        


@login_required
@bp.route("/rentals/<int:rental_id>/return", methods=("POST",))
def return_rental(rental_id):
    db = get_db()
    rental = db.execute(
        """
        SELECT customer_id, rental_id, store_id, film_id, return_date
        FROM pagila.rental
        INNER JOIN pagila.inventory USING (inventory_id)
        WHERE rental_id = %s
        """, (rental_id,)).fetchone()
    error = None
    
    if not rental:
        error = "Can't return a rental that doesn't exist"
    elif rental.customer_id != g.customer.customer_id:
        error = "Can't return a rental that isn't yours"
    elif rental.return_date is not None:
        error = "Can't return a rental that's already returned"

    if error is None:
        db.execute(
            """
            UPDATE pagila.rental
            SET return_date = now()
            WHERE rental_id = %s
            """, (rental_id,))
    else:
        flash(error, "danger")
    
    film = get_film(rental.store_id, rental.film_id)
    
    return render_block("inventory/films.html", 'film_entry', store_id=rental.store_id, film=film)