app [main] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.5.0/Vq-iXfrRf-aHxhJpAh71uoVUlC-rsWvmjzTYOJKhu4M.tar.br",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.6.0/IOyNfA4U_bCVBihrs95US9Tf5PGAWh3qvrBN4DRbK5c.tar.br",
    ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.1.1/cPHdNPNh8bjOrlOgfSaGBJDz6VleQwsPdW0LJK6dbGQ.tar.br",
}

import pf.Stdout
import pf.Stderr
import pf.Task exposing [Task]
import pf.Http exposing [Request, Response]
import pf.Env
import pf.Utc
import pf.Url exposing [Url]
import pf.SQLite3
import html.Html
import html.Attribute
import ansi.Color
import "site.css" as stylesFile : List U8
import "site.js" as siteFile : List U8
import Sql.Todo
import Sql.Session
import Sql.User
import Model exposing [Session, Todo]
import Pages.Home
import Pages.Login
import Pages.Register
import Pages.Todo
import Pages.UserList
import Pages.TreeView

main : Request -> Task Response []
main = \req ->

    # Log the date, time, method, and url to stdout
    {} <- logRequest req |> Task.await

    # Read DB_PATH environment variable
    dbPath <-
        Env.var "DB_PATH"
        |> Task.onErr \_ -> crash "unable to read DB_PATH environment variable"
        |> Task.await

    maybeSession <- Sql.Session.parse req |> Sql.Session.get dbPath |> Task.attempt
    when maybeSession is
        # Session cookie should be sent with each request
        Ok session -> handleReq session dbPath req |> Task.onErr handleErr
        # If this is a new session we should create one and return it
        Err SessionNotFound ->
            maybeNewSession <- Sql.Session.new dbPath |> Task.attempt

            when maybeNewSession is
                Err err -> handleErr err
                Ok sessionId ->
                    Task.ok {
                        status: 303,
                        headers: [
                            { name: "Set-Cookie", value: Str.toUtf8 "sessionId=$(Num.toStr sessionId)" },
                            { name: "Location", value: Str.toUtf8 req.url },
                        ],
                        body: [],
                    }

        # Handle any server errors
        Err err -> handleErr err

handleReq : Session, Str, Request -> Task Response _
handleReq = \session, dbPath, req ->

    urlSegments =
        req.url
        |> Url.fromStr
        |> Url.path
        |> Str.split "/"
        |> List.dropFirst 1

    when (req.method, urlSegments) is
        (Get, [""]) -> Pages.Home.view { session } |> htmlResponse |> Task.ok
        (Get, ["robots.txt"]) -> staticReponse robotsTxt
        (Get, ["styles.css"]) -> staticReponse stylesFile
        (Get, ["site.js"]) -> staticReponse siteFile
        (Get, ["register"]) ->
            Pages.Register.view { session, user: Fresh, email: Valid } |> htmlResponse |> Task.ok

        (Post, ["register"]) ->
            params = Http.parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})

            usernameResult = Dict.get params "user"
            emailResult = Dict.get params "email"

            when (usernameResult, emailResult) is
                (Ok username, Ok email) ->
                    Sql.User.register { path: dbPath, name: username, email }
                    |> Task.attempt \result ->
                        when result is
                            Ok {} -> redirect "/login" ## Redirect to login page after successful registration
                            Err UserAlreadyExists -> Pages.Register.view { session, user: UserAlreadyExists username, email: Valid } |> htmlResponse |> Task.ok
                            Err err -> handleErr err

                _ ->
                    Pages.Register.view { session, user: UserNotProvided, email: NotProvided }
                    |> htmlResponse
                    |> Task.ok

        (Get, ["login"]) ->
            Pages.Login.view { session, user: Fresh } |> htmlResponse |> Task.ok

        (Post, ["login"]) ->
            params = Http.parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})

            when Dict.get params "user" is
                Err _ -> Pages.Login.view { session, user: UserNotProvided } |> htmlResponse |> Task.ok
                Ok username ->
                    Sql.User.login dbPath session.id username
                    |> Task.attempt \result ->
                        when result is
                            Ok {} -> redirect "/"
                            Err (UserNotFound _) -> Pages.Login.view { session, user: UserNotFound username } |> htmlResponse |> Task.ok
                            Err err -> handleErr err

        (Post, ["logout"]) ->
            maybeNewSession <- Sql.Session.new dbPath |> Task.attempt

            when maybeNewSession is
                Err err -> handleErr err
                Ok sessionId ->
                    Task.ok {
                        status: 303,
                        headers: [
                            { name: "Set-Cookie", value: Str.toUtf8 "sessionId=$(Num.toStr sessionId)" },
                            { name: "Location", value: Str.toUtf8 "/" },
                        ],
                        body: [],
                    }

        (Get, ["task", "new"]) -> redirect "/task"
        (Post, ["task", idStr, "delete"]) ->
            {} <- Sql.Todo.delete { path: dbPath, userId: idStr } |> Task.await

            tasks <- Sql.Todo.list { path: dbPath, filterQuery: "" } |> Task.await

            Pages.Todo.listTodoView { todos: tasks, filterQuery: "" } |> htmlResponse |> Task.ok

        (Post, ["task", "search"]) ->
            params = Http.parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})

            filterQuery = Dict.get params "filterTasks" |> Result.withDefault ""

            tasks <- Sql.Todo.list { path: dbPath, filterQuery } |> Task.await

            Pages.Todo.listTodoView { todos: tasks, filterQuery } |> htmlResponse |> Task.ok

        (Post, ["task", "new"]) ->
            newTodo <- parseTodo req.body |> Task.fromResult |> Task.await

            Sql.Todo.create { path: dbPath, newTodo }
            |> Task.attempt \result ->
                when result is
                    Ok {} -> redirect "/task"
                    Err TaskWasEmpty -> redirect "/task"
                    Err err -> handleErr err

        (Put, ["task", taskIdStr, "complete"]) ->
            {} <- Sql.Todo.update { path: dbPath, taskIdStr, action: Completed } |> Task.await

            triggerResponse "todosUpdated"

        (Put, ["task", taskIdStr, "in-progress"]) ->
            {} <- Sql.Todo.update { path: dbPath, taskIdStr, action: InProgress } |> Task.await

            triggerResponse "todosUpdated"

        (Get, ["task", "list"]) ->
            tasks <- Sql.Todo.list { path: dbPath, filterQuery: "" } |> Task.await

            Pages.Todo.listTodoView { todos: tasks, filterQuery: "" } |> htmlResponse |> Task.ok

        (Get, ["task"]) ->
            tasks <- Sql.Todo.list { path: dbPath, filterQuery: "" } |> Task.await

            Pages.Todo.view { todos: tasks, filterQuery: "", session } |> htmlResponse |> Task.ok

        (Get, ["treeview"]) ->
            nodes <- Sql.Todo.tree { path: dbPath, userId: 1 } |> Task.await

            Pages.TreeView.view { session, nodes } |> htmlResponse |> Task.ok

        (Get, ["user"]) ->
            users <- Sql.User.list dbPath |> Task.await

            Pages.UserList.view { users, session } |> htmlResponse |> Task.ok

        _ -> Task.err (URLNotFound req.url)

parseTodo : List U8 -> Result Todo [UnableToParseBodyTask _]_
parseTodo = \bytes ->
    dict = Http.parseFormUrlEncoded bytes |> Result.withDefault (Dict.empty {})

    task <-
        Dict.get dict "task"
        |> Result.mapErr \_ -> UnableToParseBodyTask bytes
        |> Result.try

    status <-
        Dict.get dict "status"
        |> Result.mapErr \_ -> UnableToParseBodyTask bytes
        |> Result.try

    Ok { id: 0, task, status }

triggerResponse : Str -> Task Response []_
triggerResponse = \trigger ->
    Task.ok {
        status: 200,
        headers: [
            { name: "HX-Trigger", value: Str.toUtf8 trigger },
        ],
        body: [],
    }

staticReponse : List U8 -> Task Response []_
staticReponse = \bytes ->
    Task.ok {
        status: 200,
        headers: [
            { name: "Cache-Control", value: Str.toUtf8 "max-age=120" },
        ],
        body: bytes,
    }

htmlResponse : Html.Node -> Response
htmlResponse = \node -> {
    status: 200,
    headers: [
        { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
    ],
    body: Str.toUtf8 (Html.render node),
}

redirect : Str -> Task Response []_
redirect = \next ->
    Task.ok {
        status: 303,
        headers: [
            { name: "Location", value: Str.toUtf8 next },
        ],
        body: [],
    }

handleErr : _ -> Task Response []_
handleErr = \err ->

    (msg, code) =
        when err is
            URLNotFound url -> (Str.joinWith ["404 NotFound" |> Color.fg Blue, url] " ", 404)
            _ -> (Str.joinWith ["SERVER ERROR" |> Color.fg Red, Inspect.toStr err] " ", 500)

    {} <- Stderr.line msg |> Task.await

    Task.ok {
        status: code,
        headers: [],
        body: [],
    }

logRequest : Request -> Task {} *
logRequest = \req ->
    dateTime <- Utc.now |> Task.map Utc.toIso8601Str |> Task.await

    reqBody = req.body |> Str.fromUtf8 |> Result.withDefault "<invalid utf8 body>"

    Stdout.line "$(dateTime) $(Http.methodToStr req.method) $(req.url) $(reqBody)"

robotsTxt : List U8
robotsTxt =
    """
    User-agent: *
    Disallow: /
    """
    |> Str.toUtf8
