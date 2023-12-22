Based on the [flask tutorial example](https://github.com/pallets/flask/tree/main/examples/tutorial)

```sh
export PAGILA_DB="postgresql://bdr:bdr@localhost:5432/bdr" 
flask --app pagila-ui init-db
flask --app pagila-ui run --debug
```