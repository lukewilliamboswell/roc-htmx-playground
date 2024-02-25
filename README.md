# roc + htmx playground

- Explore [roc](https://www.roc-lang.org) and [htmx](https://htmx.org) for app development
- Add new features to [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver)
- Generally tinker and have fun

Any PR's or ideas welcome. You are welcome to play with this and if you have something to share then please do. 

## Getting Started

Ensure `sqlite3` and `roc` are on your `PATH`

**create test.db** `rm -rf test.db && sqlite3 test.db < test.sql`

**start server** `DB_PATH=test.db roc dev src/main.roc`

