app [Model, init!, respond!] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.13.0/fSNqJj3-twTrb0jJKHreMimVWD7mebDOj0mnslMm2GM.tar.br",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.8.0/GCTX3ckGRXs29XkLh0rhp0a6l0IrUe5RgAFj83hwN3Q.tar.br",
}

import html.Html

import pf.Stdout
import pf.Stderr
import pf.Http exposing [Request, Response]
import pf.MultipartFormData
import pf.Env
import pf.Utc
import pf.Url
import "site.css" as styles_file : List U8
import "site.js" as site_file : List U8
import "../vendor/bootstrap.bundle-5-3-2.min.js" as bootstrap_js_file : List U8
import "../vendor/bootstrap-5-3-2.min.css" as bootstrap_css_file : List U8
import "../vendor/htmx-2-0-3.min.js" as htmx_js_file : List U8
import Helpers
import Sql.Todo
import Sql.Session
import Sql.User
import Models.Session exposing [Session]
import Models.Todo exposing [Todo]
import Views.Home
import Views.Unauthorised
import Views.Login
import Views.Register
import Views.Todo
import Views.UserList
import Views.TreeView
import Controllers.BigTask

Model : {}

init! : {} => Result Model []
init! = \{} -> Ok {}

respond! : Request, Model => Result Response [ServerErr Str]
respond! = \req, _ ->
    when handle_req! req is
        Ok response -> Ok response
        Err err ->
            when err is
                BadRequest inner ->
                    _ = Stderr.line! (Inspect.to_str err)
                    Ok {
                        status: 400,
                        headers: [],
                        body: Str.to_utf8 (Inspect.to_str inner),
                    }

                Unauthorized ->
                    Ok (Views.Unauthorised.page {} |> to_html_response [])

                NewSession session_id ->
                    Ok {
                        status: 303,
                        headers: [
                            { name: "Set-Cookie", value: "sessionId=$(Num.to_str session_id)" },
                            { name: "Location", value: req.uri },
                        ],
                        body: [],
                    }

                URLNotFound url ->
                    _ = Stderr.line! (Str.join_with ["404 NotFound", url] " ")
                    Ok {
                        status: 404,
                        headers: [],
                        body: [],
                    }

                _ ->
                    _ = Stderr.line! (Str.join_with ["SERVER ERROR", Inspect.to_str err] " ")
                    Ok {
                        status: 500,
                        headers: [],
                        body: [],
                    }

handle_req! : Request => Result Response _
handle_req! = \req ->
    log_request! req

    db_path = try (Env.var! "DB_PATH" |> Result.map_err UnableToReadDbPATH)

    session = try get_session! req db_path

    url_segments =
        req.uri
        |> Url.from_str
        |> Url.path
        |> Str.split_on "/"
        |> List.drop_first 1

    when (req.method, url_segments) is
        (GET, [""]) -> Ok (Views.Home.page { session } |> to_html_response [])
        (GET, ["robots.txt"]) -> Ok (respond_static robots_txt)
        (GET, ["styles.css"]) -> Ok (respond_static styles_file)
        (GET, ["site.js"]) -> Ok (respond_static site_file)
        (GET, ["bootstrap.bundle.min.js"]) -> Ok (respond_static bootstrap_js_file)
        (GET, ["bootstrap.min.css"]) -> Ok (respond_static bootstrap_css_file)
        (GET, ["htmx.min.js"]) -> Ok (respond_static htmx_js_file)
        (GET, ["register"]) ->
            Ok (Views.Register.page { user: Fresh, email: Valid } |> to_html_response [])

        (POST, ["register"]) ->
            params = MultipartFormData.parse_form_url_encoded req.body |> Result.with_default (Dict.empty {})

            when (Dict.get params "user", Dict.get params "email") is
                (Ok username, Ok email) ->
                    when Sql.User.register! { path: db_path, name: username, email } is
                        Ok {} -> Helpers.respond_redirect "/login"
                        Err UserAlreadyExists -> Ok (Views.Register.page { user: UserAlreadyExists username, email: Valid } |> to_html_response [])
                        Err err -> Err (ErrRegisteringUser (Inspect.to_str err))

                _ ->
                    Ok (Views.Register.page { user: UserNotProvided, email: NotProvided } |> to_html_response [])

        (GET, ["login"]) ->
            Ok (Views.Login.page { session, user: Fresh } |> to_html_response [])

        (POST, ["login"]) ->
            params = MultipartFormData.parse_form_url_encoded req.body |> Result.with_default (Dict.empty {})

            when Dict.get params "user" is
                Err _ -> Ok (Views.Login.page { session, user: UserNotProvided } |> to_html_response [])
                Ok username ->
                    when Sql.User.login! db_path session.id username is
                        Ok {} -> Helpers.respond_redirect "/"
                        Err (UserNotFound _) -> Ok (Views.Login.page { session, user: UserNotFound username } |> to_html_response [])
                        Err err -> Err (ErrUserLogin (Inspect.to_str err))

        (POST, ["logout"]) ->
            id = try Sql.Session.new! db_path

            Ok {
                status: 303,
                headers: [
                    { name: "Set-Cookie", value: "sessionId=$(Num.to_str id)" },
                    { name: "Location", value: "/" },
                ],
                body: [],
            }

        (GET, ["task", "new"]) -> Helpers.respond_redirect "/task"
        (POST, ["task", id_str, "delete"]) ->
            try Sql.Todo.delete! { path: db_path, user_id: id_str }

            tasks = try Sql.Todo.list! { path: db_path, filter_query: "" }

            Ok (Views.Todo.list_todo_view { todos: tasks, filter_query: "" } |> to_html_response [])

        (POST, ["task", "search"]) ->
            params = MultipartFormData.parse_form_url_encoded req.body |> Result.with_default (Dict.empty {})

            filter_query = Dict.get params "filterTasks" |> Result.with_default ""

            tasks = try Sql.Todo.list! { path: db_path, filter_query }

            Ok (Views.Todo.list_todo_view { todos: tasks, filter_query } |> to_html_response [])

        (POST, ["task", "new"]) ->
            new_todo = try parse_todo req.body

            when Sql.Todo.create! { path: db_path, new_todo } is
                Ok {} -> Helpers.respond_redirect "/task"
                Err TaskWasEmpty -> Helpers.respond_redirect "/task"
                Err err -> Err (ErrTodoCreate (Inspect.to_str err))

        (PUT, ["task", task_id_str, "complete"]) ->
            try Sql.Todo.update! { path: db_path, task_id_str, action: Completed }

            Ok (respond_hx_trigger "todosUpdated")

        (PUT, ["task", task_id_str, "in-progress"]) ->
            try Sql.Todo.update! { path: db_path, task_id_str, action: InProgress }

            Ok (respond_hx_trigger "todosUpdated")

        (GET, ["task", "list"]) ->
            tasks = try Sql.Todo.list! { path: db_path, filter_query: "" }

            Ok (Views.Todo.list_todo_view { todos: tasks, filter_query: "" } |> to_html_response [])

        (GET, ["task"]) ->
            tasks = try Sql.Todo.list! { path: db_path, filter_query: "" }

            Ok (Views.Todo.page { todos: tasks, filter_query: "", session } |> to_html_response [])

        (GET, ["treeview"]) ->
            nodes = try Sql.Todo.tree! { path: db_path, user_id: 1 }

            Ok (Views.TreeView.page { session, nodes } |> to_html_response [])

        (GET, ["user"]) ->
            users = try Sql.User.list! db_path

            Ok (Views.UserList.page { users, session } |> to_html_response [])

        (_, ["bigTask", ..]) ->
            Controllers.BigTask.respond! { req, url_segments: List.drop_first url_segments 1, db_path, session }

        _ -> Err (URLNotFound req.uri)

get_session! : Request, Str => Result Session _
get_session! = \req, db_path ->
    when Sql.Session.parse req is
        Ok id ->
            when Sql.Session.get! id db_path is
                Ok session -> Ok session
                Err SessionNotFound ->
                    id2 = try Sql.Session.new! db_path
                    Err (NewSession id2)
                Err err -> Err err
        Err NoSessionCookie ->
            id = try Sql.Session.new! db_path
            Err (NewSession id)
        Err err -> Err err

parse_todo : List U8 -> Result Todo _
parse_todo = \bytes ->
    dict = MultipartFormData.parse_form_url_encoded bytes |> Result.with_default (Dict.empty {})

    when (Dict.get dict "task", Dict.get dict "status") is
        (Ok task, Ok status) -> Ok { id: 0, task, status }
        _ -> Err (UnableToParseBodyTask bytes)

respond_hx_trigger : Str -> Response
respond_hx_trigger = \trigger ->
    {
        status: 200,
        headers: [
            { name: "HX-Trigger", value: trigger },
        ],
        body: [],
    }

respond_static : List U8 -> Response
respond_static = \bytes ->
    {
        status: 200,
        headers: [
            { name: "Cache-Control", value: "max-age=120" },
        ],
        body: bytes,
    }

to_html_response : Html.Node, List { name : Str, value : Str } -> Response
to_html_response = \node, other_headers ->
    {
        status: 200,
        headers: [{ name: "Content-Type", value: "text/html; charset=utf-8" }]
            |> List.concat other_headers,
        body: Str.to_utf8 (Html.render node),
    }

log_request! : Request => {}
log_request! = \req ->
    date = Utc.now! {} |> Utc.to_iso_8601
    method = Inspect.to_str req.method
    url = req.uri
    body = req.body |> Str.from_utf8 |> Result.with_default "<invalid utf8 body>"
    _ = Stdout.line! "$(date) $(method) $(url) $(body)"
    {}

robots_txt : List U8
robots_txt =
    """
    User-agent: *
    Disallow: /
    """
    |> Str.to_utf8
