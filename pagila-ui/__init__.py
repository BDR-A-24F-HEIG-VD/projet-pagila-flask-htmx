import os
from flask import Flask

def create_app(test_config=None):
    """Create and configure an instance of the Flask application."""
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_mapping(
        # a default secret that should be overridden by instance config
        SECRET_KEY="dev",
        # store the database in the instance folder
        DATABASE=os.environ["PAGILA_DB"],
    )

    # register the database commands
    from . import db

    db.init_app(app)

    # apply the blueprints to the app
    from . import auth
    from . import inventory

    app.register_blueprint(auth.bp)
    app.register_blueprint(inventory.bp)

    # make url_for('index') == url_for('inventory.index')
    # in another app, you might define a separate main index here with
    # app.route, while giving the inventory blueprint a url_prefix, but for
    # the tutorial the inventory will be the main index
    app.add_url_rule("/", view_func=inventory.index)

    return app