# roc + htmx playground

- Explore [roc](https://www.roc-lang.org) and [htmx](https://htmx.org) for app development
- Add new features to [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver)
- Generally tinker and have fun

> **Note:** This project uses modern Roc syntax and
> [basic-webserver 0.14.0](https://github.com/roc-lang/basic-webserver/releases/tag/0.14.0).

Any PR's or ideas welcome.

You are welcome to play with this and if you have something to share then please do.

![demo](demo.gif)

## Getting Started

Ensure `sqlite3` and `roc` are on your `PATH`

**create test.db** `rm -rf test.db && sqlite3 test.db < test.sql`

**start server** `DB_PATH=test.db roc src/main.roc`

**change port** Set `ROC_BASIC_WEBSERVER_PORT` to run on a different port, e.g.
`DB_PATH=test.db ROC_BASIC_WEBSERVER_PORT=8080 roc src/main.roc`

The server opens the SQLite connection pool once during `init!` and shares it
with request handlers through immutable application context.
