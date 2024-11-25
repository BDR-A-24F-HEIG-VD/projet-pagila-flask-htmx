import functools

from flask import Blueprint
from flask import flash
from flask import g
from flask import redirect
from flask import render_template
from flask import request
from flask import session
from flask import url_for

from .db import get_db

bp = Blueprint("auth", __name__, url_prefix="/auth")


def login_required(view):
    """View decorator that redirects anonymous users to the login page."""

    @functools.wraps(view)
    def wrapped_view(**kwargs):
        # Check if the customer property was set in the application context.
        if g.customer is None:
            return redirect(url_for("auth.login"))

        return view(**kwargs)

    return wrapped_view


@bp.before_app_request
def load_logged_in_customer():
    """If a customer id is stored in the session (cookie), load the user object from
    the database into ``g.customer``."""
    customer_id = session.get("customer_id")

    if customer_id is None:
        g.customer = None
    else:
        db = get_db()
        g.customer = db.execute(
            "SELECT * FROM pagila.customer WHERE customer_id = %(customer_id)s",
            dict(customer_id=customer_id),
        ).fetchone()


@bp.route("/login", methods=("GET", "POST"))
def login():
    """Log in a registered customer by adding the customer id to the session."""
    if request.method == "POST":
        email = request.form["email"]

        db = get_db()
        error = None
        customer = db.execute(
            "SELECT * FROM pagila.customer WHERE email = %(email)s",
            dict(email=email),
        ).fetchone()

        if customer is None:
            error = "Incorrect email."

        if error is None:
            # store the customer id in a new session and return to the index
            session.clear()
            session["customer_id"] = customer.customer_id
            return redirect(url_for("index"))

        flash(error)

    return render_template("auth/login.html")


@bp.route("/logout")
def logout():
    """Clear the current session, including the stored user id."""
    session.clear()
    return redirect(url_for("index"))
