app [main] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.5.0/Vq-iXfrRf-aHxhJpAh71uoVUlC-rsWvmjzTYOJKhu4M.tar.br",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.6.0/IOyNfA4U_bCVBihrs95US9Tf5PGAWh3qvrBN4DRbK5c.tar.br",
    ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.1.1/cPHdNPNh8bjOrlOgfSaGBJDz6VleQwsPdW0LJK6dbGQ.tar.br",
    #json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.10.0/KbIfTNbxShRX1A1FgXei1SpO5Jn8sgP6HP6PXbi-xyA.tar.br",
}

import pf.Stdout
import pf.Stderr
import pf.Task exposing [Task]
import pf.Http exposing [Request, Response]
import pf.Env
import pf.Utc
import pf.Url
#import json.Json
import ansi.Color
import "site.css" as stylesFile : List U8
import "site.js" as siteFile : List U8
import "../vendor/bootsrap.bundle-5-3-2.min.js" as bootstrapJSFile : List U8
import "../vendor/bootstrap-5-3-2.min.css" as bootsrapCSSFile : List U8
import "../vendor/htmx-1-9-9.min.js" as htmxJSFile : List U8
import Helpers exposing [respondHtml]
import Sql.Todo
import Sql.Session
import Sql.User
import Models.Session exposing [Session]
import Models.Todo exposing [Todo]
import Views.Home
import Views.Login
import Views.Register
import Views.Todo
import Views.UserList
import Views.TreeView
import Controllers.BigTask

main : Request -> Task Response []
main = \req -> Task.onErr (handleReq req) \err ->
        when err is

            BadRequest inner ->
                Stderr.line! (Inspect.toStr err)
                Task.ok {
                    status: 400,
                    headers: [],
                    body: Str.toUtf8 (Inspect.toStr inner),
                }

            Unauthorized ->
                import Views.Unauthorised
                Views.Unauthorised.page {} |> respondHtml []

            NewSession sessionId ->
                # Redirect to the same URL with the new session ID
                Task.ok {
                    status: 303,
                    headers: [
                        { name: "Set-Cookie", value: Str.toUtf8 "sessionId=$(Num.toStr sessionId)" },
                        { name: "Location", value: Str.toUtf8 req.url },
                    ],
                    body: [],
                }

            URLNotFound url -> respondCodeLogError (Str.joinWith ["404 NotFound" |> Color.fg Red, url] " ") 404
            _ -> respondCodeLogError (Str.joinWith ["SERVER ERROR" |> Color.fg Red, Inspect.toStr err] " ") 500

handleReq : Request -> Task Response _
handleReq = \req ->

    logRequest! req # Log the date, time, method, and url to stdout

    dbPath = Env.var "DB_PATH" |> Task.mapErr! UnableToReadDbPATH

    session = getSession! req dbPath

    urlSegments =
        req.url
        |> Url.fromStr
        |> Url.path
        |> Str.split "/"
        |> List.dropFirst 1

    when (req.method, urlSegments) is
        (Get, [""]) -> Views.Home.page { session } |> respondHtml []
        (Get, ["bootsrap.bundle-5-3-2.min.js"]) -> respondStatic bootstrapJSFile
        (Get, ["bootstrap-5-3-2.min.css"]) -> respondStatic bootsrapCSSFile
        (Get, ["htmx-1-9-9.min.js"]) -> respondStatic htmxJSFile
        (Get, ["robots.txt"]) -> respondStatic robotsTxt
        (Get, ["styles.css"]) -> respondStatic stylesFile
        (Get, ["site.js"]) -> respondStatic siteFile
        (Get, ["register"]) ->
            Views.Register.page { user: Fresh, email: Valid } |> respondHtml []

        (Post, ["register"]) ->
            params = Http.parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})

            when (Dict.get params "user", Dict.get params "email") is
                (Ok username, Ok email) ->
                    Sql.User.register { path: dbPath, name: username, email }
                    |> Task.attempt \result ->
                        when result is
                            Ok {} -> Helpers.respondRedirect "/login" ## Redirect to login page after successful registration
                            Err UserAlreadyExists -> Views.Register.page { user: UserAlreadyExists username, email: Valid } |> respondHtml []
                            Err err -> Task.err (ErrRegisteringUser (Inspect.toStr err))

                _ ->
                    Views.Register.page { user: UserNotProvided, email: NotProvided } |> respondHtml []

        (Get, ["login"]) ->
            Views.Login.page { session, user: Fresh } |> respondHtml []

        (Post, ["login"]) ->
            params = Http.parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})

            when Dict.get params "user" is
                Err _ -> Views.Login.page { session, user: UserNotProvided } |> respondHtml []
                Ok username ->
                    Sql.User.login dbPath session.id username
                    |> Task.attempt \result ->
                        when result is
                            Ok {} -> Helpers.respondRedirect "/"
                            Err (UserNotFound _) -> Views.Login.page { session, user: UserNotFound username } |> respondHtml []
                            Err err -> Task.err (ErrUserLogin (Inspect.toStr err))

        (Post, ["logout"]) ->
            id = Sql.Session.new! dbPath

            Task.ok {
                status: 303,
                headers: [
                    { name: "Set-Cookie", value: Str.toUtf8 "sessionId=$(Num.toStr id)" },
                    { name: "Location", value: Str.toUtf8 "/" },
                ],
                body: [],
            }

        (Get, ["task", "new"]) -> Helpers.respondRedirect "/task"
        (Post, ["task", idStr, "delete"]) ->
            Sql.Todo.delete! { path: dbPath, userId: idStr }

            tasks = Sql.Todo.list! { path: dbPath, filterQuery: "" }

            Views.Todo.listTodoView { todos: tasks, filterQuery: "" } |> respondHtml []

        (Post, ["task", "search"]) ->
            params = Http.parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})

            filterQuery = Dict.get params "filterTasks" |> Result.withDefault ""

            tasks = Sql.Todo.list! { path: dbPath, filterQuery }

            Views.Todo.listTodoView { todos: tasks, filterQuery } |> respondHtml []

        (Post, ["task", "new"]) ->
            newTodo = parseTodo req.body |> Task.fromResult!

            when Sql.Todo.create { path: dbPath, newTodo } |> Task.result! is
                Ok {} -> Helpers.respondRedirect "/task"
                Err TaskWasEmpty -> Helpers.respondRedirect "/task"
                Err err -> Task.err (ErrTodoCreate (Inspect.toStr err))

        (Put, ["task", taskIdStr, "complete"]) ->
            Sql.Todo.update! { path: dbPath, taskIdStr, action: Completed }

            respondHxTrigger "todosUpdated"

        (Put, ["task", taskIdStr, "in-progress"]) ->
            Sql.Todo.update! { path: dbPath, taskIdStr, action: InProgress }

            respondHxTrigger "todosUpdated"

        (Get, ["task", "list"]) ->
            tasks = Sql.Todo.list! { path: dbPath, filterQuery: "" }

            Views.Todo.listTodoView { todos: tasks, filterQuery: "" } |> respondHtml []

        (Get, ["task"]) ->
            tasks = Sql.Todo.list! { path: dbPath, filterQuery: "" }

            Views.Todo.page { todos: tasks, filterQuery: "", session } |> respondHtml []

        (Get, ["treeview"]) ->
            nodes = Sql.Todo.tree! { path: dbPath, userId: 1 }

            Views.TreeView.page { session, nodes } |> respondHtml []

        (Get, ["user"]) ->
            users = Sql.User.list! dbPath

            Views.UserList.page { users, session } |> respondHtml []

        (_, ["bigTask", ..]) ->
            Controllers.BigTask.respond { req, urlSegments : List.dropFirst urlSegments 1, dbPath, session }

        _ -> Task.err (URLNotFound req.url)

getSession : Request, Str -> Task Session _
getSession = \req, dbPath  ->
    Sql.Session.parse req
        |> Task.fromResult
        |> Task.await \id -> Sql.Session.get id dbPath
        |> Task.onErr \err ->
            if err == SessionNotFound || err == NoSessionCookie then
                id = Sql.Session.new! dbPath

                Task.err (NewSession id)
            else
                Task.err err

parseTodo : List U8 -> Result Todo _
parseTodo = \bytes ->
    dict = Http.parseFormUrlEncoded bytes |> Result.withDefault (Dict.empty {})

    when (Dict.get dict "task", Dict.get dict "status") is
        (Ok task, Ok status) -> Ok { id: 0, task, status }
        _ -> Err (UnableToParseBodyTask bytes)

respondHxTrigger : Str -> Task Response []_
respondHxTrigger = \trigger ->
    Task.ok {
        status: 200,
        headers: [
            { name: "HX-Trigger", value: Str.toUtf8 trigger },
        ],
        body: [],
    }

respondStatic : List U8 -> Task Response []_
respondStatic = \bytes ->
    Task.ok {
        status: 200,
        headers: [
            { name: "Cache-Control", value: Str.toUtf8 "max-age=120" },
        ],
        body: bytes,
    }

respondCodeLogError = \msg, code ->
    Stderr.line! msg
    Task.ok! {
        status: code,
        headers: [],
        body: [],
    }

logRequest : Request -> Task {} *
logRequest = \req ->
    date = Utc.now |> Task.map! Utc.toIso8601Str
    method = Http.methodToStr req.method
    url = req.url
    body = req.body |> Str.fromUtf8 |> Result.withDefault "<invalid utf8 body>"
    Stdout.line! "$(date) $(method) $(url) $(body)"

robotsTxt : List U8
robotsTxt =
    """
    User-agent: *
    Disallow: /
    """
    |> Str.toUtf8
