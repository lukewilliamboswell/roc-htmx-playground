app [main, Model] {
    webserver: platform "https://github.com/ostcar/kingfisher/releases/download/v0.0.3/e8Mu5IplmOnXPU9VgpTCT6kyB463gX-SDC2nnMfAq7M.tar.br",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.6.0/IOyNfA4U_bCVBihrs95US9Tf5PGAWh3qvrBN4DRbK5c.tar.br",
    # json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.10.0/KbIfTNbxShRX1A1FgXei1SpO5Jn8sgP6HP6PXbi-xyA.tar.br",
}

import webserver.Webserver exposing [Request, Response]
import html.Html
import Models.Session exposing [Session, User]
import Models.Todo exposing [Todo]
# import json.Json
import "site.css" as stylesFile : List U8
import "site.js" as siteFile : List U8
import "../vendor/bootsrap.bundle-5-3-2.min.js" as bootstrapJSFile : List U8
import "../vendor/bootstrap-5-3-2.min.css" as bootsrapCSSFile : List U8
import "../vendor/htmx-1-9-9.min.js" as htmxJSFile : List U8
import Views.Home
import Views.Login
import Views.Register
import Views.Todo
import Views.UserList
import Url

Model : {
    sessions : List Session,
    users : List User,
    todos : List Todo,
}

main = {
    decodeModel,
    encodeModel,
    handleReadRequest,
    handleWriteRequest,
}

decodeModel : [Init, Existing (List U8)] -> Result Model Str
decodeModel = \_fromPlatform ->
    Ok {
        sessions: [],
        users: [],
        todos: [],
    }
# when fromPlatform is
#     Init ->
#         Ok {sessions: []}

#     Existing encoded ->
#         decoder = Json.utf8With { fieldNameMapping: PascalCase }

#         decoded : Decode.DecodeResult Model
#         decoded = Decode.fromBytesPartial encoded decoder
#         decoded.result
#         |> Result.mapErr \_ -> "Error: Can not decode database."

encodeModel : Model -> List U8
encodeModel = \_model ->
    # Encode.toBytes model Json.utf8
    []

handleReadRequest : Request, Model -> Response
handleReadRequest = \req, model ->
    session = parseSession req model.sessions

    urlSegments =
        req.url
        |> Url.fromStr
        |> Url.path
        |> Str.splitOn "/"
        |> List.dropFirst 1

    when (req.method, urlSegments) is
        (Get, [""]) -> Views.Home.page { session } |> htmlResponse
        (Get, ["robots.txt"]) -> staticReponse robotsTxt
        (Get, ["styles.css"]) -> staticReponse stylesFile
        (Get, ["site.js"]) -> staticReponse siteFile
        (Get, ["bootsrap.bundle-5-3-2.min.js"]) -> staticReponse bootstrapJSFile
        (Get, ["bootstrap-5-3-2.min.css"]) -> staticReponse bootsrapCSSFile
        (Get, ["htmx-1-9-9.min.js"]) -> staticReponse htmxJSFile
        (Get, ["register"]) ->
            Views.Register.page { user: Fresh, email: Valid } |> htmlResponse

        (Get, ["login"]) ->
            Views.Login.page { session, user: Fresh } |> htmlResponse

        (Get, ["task", "new"]) -> redirect "/task"
        (Get, ["task", "list"]) ->
            Views.Todo.listTodoView { todos: model.todos, filterQuery: "" } |> htmlResponse

        (Get, ["task"]) ->
            Views.Todo.page { todos: model.todos, filterQuery: "", session } |> htmlResponse

        # (Get, ["treeview"]) ->
        #     nodes <- Sql.Todo.tree { path: dbPath, userId: 1 } |> Task.await
        #     Views.TreeView.page { session, nodes } |> htmlResponse |> Task.ok
        (Get, ["user"]) ->
            Views.UserList.page { users: model.users, session } |> htmlResponse

        _ -> handleErr (URLNotFound req.url)

handleWriteRequest : Request, Model -> (Response, Model)
handleWriteRequest = \req, model ->
    session = parseSession req model.sessions

    urlSegments =
        req.url
        |> Url.fromStr
        |> Url.path
        |> Str.splitOn "/"
        |> List.dropFirst 1

    when (req.method, urlSegments) is
        (Post, ["register"]) ->
            params = parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})
            usernameResult = Dict.get params "user"
            emailResult = Dict.get params "email"
            when (usernameResult, emailResult) is
                (Ok username, Ok email) ->
                    when List.findFirst model.users (\u -> u.name == username) is
                        Ok _user -> Views.Register.page { user: UserAlreadyExists username, email: Valid } |> htmlResponse |> \resp -> (resp, model)
                        Err _ ->
                            newUser = {
                                id: List.len model.users |> Num.toI64,
                                email: email,
                                name: username,
                            }
                            newModel = { model & users: List.append model.users newUser }
                            (redirect "/login", newModel)

                _ ->
                    Views.Register.page { user: UserNotProvided, email: NotProvided } |> htmlResponse |> \resp -> (resp, model)

        (Post, ["login"]) ->
            params = parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})

            when Dict.get params "user" is
                Err _ -> Views.Login.page { session, user: UserNotProvided } |> htmlResponse |> \resp -> (resp, model)
                Ok username ->
                    when List.findFirst model.users (\u -> u.name == username) is
                        Ok _user ->
                            sessionID = List.len model.sessions |> Num.toI64
                            newmodel = { model & sessions: List.append model.sessions { id: sessionID, user: LoggedIn username } }
                            (
                                {
                                    status: 303,
                                    headers: [
                                        { name: "Set-Cookie", value: Str.toUtf8 "$(cookieName)=$(Num.toStr sessionID)" },
                                        { name: "Location", value: Str.toUtf8 "/" },
                                    ],
                                    body: [],
                                },
                                newmodel,
                            )

                        Err NotFound -> Views.Login.page { session, user: UserNotFound username } |> htmlResponse |> \resp -> (resp, model)

        (Post, ["logout"]) ->
            newmodel = { model & sessions: List.update model.sessions (session.id |> Num.toU64) (\s -> { s & user: Guest }) }

            (
                {
                    status: 303,
                    headers: [
                        { name: "Set-Cookie", value: Str.toUtf8 "$(cookieName)=deleted;  path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT" },
                        { name: "Location", value: Str.toUtf8 "/" },
                    ],
                    body: [],
                },
                newmodel,
            )

        (Post, ["task", taskIdStr, "delete"]) ->
            newModel =
                when Str.toI64 taskIdStr |> Result.try \id -> findIndex model.todos id is
                    Ok index ->
                        { model & todos: List.dropAt model.todos index }

                    Err _ -> model

            (Views.Todo.listTodoView { todos: newModel.todos, filterQuery: "" } |> htmlResponse, newModel)

        (Post, ["task", "search"]) ->
            params = parseFormUrlEncoded req.body |> Result.withDefault (Dict.empty {})
            filterQuery = Dict.get params "filterTasks" |> Result.withDefault ""
            todos = model.todos |> List.keepIf \todo -> Str.contains todo.task filterQuery
            (Views.Todo.listTodoView { todos, filterQuery } |> htmlResponse, model)

        (Post, ["task", "new"]) ->
            when parseTodo req.body is
                Ok newTodo ->
                    nextID = (List.map model.todos \todo -> todo.id) |> List.max |> Result.withDefault 0 |> Num.add 1
                    newModel = { model & todos: List.append model.todos { newTodo & id: nextID } }
                    (redirect "/task", newModel)

                Err err -> (handleErr err, model)

        (Put, ["task", taskIdStr, "complete"]) ->
            newModel =
                when Str.toI64 taskIdStr |> Result.try \id -> findIndex model.todos id is
                    Ok id ->
                        { model & todos: List.update model.todos id \old -> { old & status: "Completed" } }

                    Err _ -> model
            (triggerResponse "todosUpdated", newModel)

        (Put, ["task", taskIdStr, "in-progress"]) ->
            newModel =
                when Str.toI64 taskIdStr |> Result.try \id -> findIndex model.todos id is
                    Ok id ->
                        { model & todos: List.update model.todos id \old -> { old & status: "In-Progress" } }

                    Err _ -> model
            (triggerResponse "todosUpdated", newModel)

        _ -> (handleErr (URLNotFound req.url), model)

findIndex = \list, id ->
    List.findFirstIndex list (\e -> e.id == id)

parseTodo : List U8 -> Result Todo [UnableToParseBodyTask _]_
parseTodo = \bytes ->
    dict = parseFormUrlEncoded bytes |> Result.withDefault (Dict.empty {})

    task <-
        Dict.get dict "task"
        |> Result.mapErr \_ -> UnableToParseBodyTask bytes
        |> Result.try

    status <-
        Dict.get dict "status"
        |> Result.mapErr \_ -> UnableToParseBodyTask bytes
        |> Result.try

    Ok { id: 0, task, status }

triggerResponse : Str -> Response
triggerResponse = \trigger -> {
    status: 200,
    headers: [
        { name: "HX-Trigger", value: Str.toUtf8 trigger },
    ],
    body: [],
}

staticReponse : List U8 -> Response
staticReponse = \bytes -> {
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

redirect : Str -> Response
redirect = \next -> {
    status: 303,
    headers: [
        { name: "Location", value: Str.toUtf8 next },
    ],
    body: [],
}

handleErr : _ -> Response
handleErr = \err ->

    code =
        when err is
            URLNotFound url -> 404
            _ -> 500

    {
        status: code,
        headers: [],
        body: [],
    }

robotsTxt : List U8
robotsTxt =
    """
    User-agent: *
    Disallow: /
    """
    |> Str.toUtf8

anonymousSession = {
    id: 0 |> Num.toI64,
    user: Guest,
}

cookieName = "sessionId"

parseSession : Request, List Session -> Session
parseSession = \req, sessions ->
    mayID =
        req.headers
        |> List.findFirst \reqHeader -> reqHeader.name == "Cookie"
        |> Result.mapErr \_ -> CookieHeaderNotFound
        |> Result.try \reqHeader ->
            reqHeader.value
            |> Str.fromUtf8
            |> Result.try \str ->
                str
                |> Str.splitOn ";"
                |> List.findFirst \v -> v |> Str.trim |> Str.startsWith "$(cookieName)="
                |> Result.mapErr \_ -> CookieNameNotFound cookieName str
                |> Result.try \w ->
                    w
                    |> Str.splitOn "="
                    |> List.get 1
                    |> Result.mapErr \_ -> NoEqualFound
                    |> Result.try \v ->
                        v
                        |> Str.toU64
                        |> Result.mapErr \_ -> ValueNoInt v

    when mayID is
        Ok id -> List.get sessions id |> Result.withDefault anonymousSession
        Err _ -> anonymousSession

# From basic-webserver
parseFormUrlEncoded : List U8 -> Result (Dict Str Str) [BadUtf8]
parseFormUrlEncoded = \bytes ->

    chainUtf8 = \bytesList, tryFun -> Str.fromUtf8 bytesList |> mapUtf8Err |> Result.try tryFun

    # simplify `BadUtf8 Utf8ByteProblem ...` error
    mapUtf8Err = \err -> err |> Result.mapErr \_ -> BadUtf8

    parse = \bytesRemaining, state, key, chomped, dict ->
        tail = List.dropFirst bytesRemaining 1

        when bytesRemaining is
            [] if List.isEmpty chomped -> dict |> Ok
            [] ->
                # chomped last value
                keyStr <- key |> chainUtf8
                valueStr <- chomped |> chainUtf8

                Dict.insert dict keyStr valueStr |> Ok

            ['=', ..] -> parse tail ParsingValue chomped [] dict # put chomped into key
            ['&', ..] ->
                keyStr <- key |> chainUtf8
                valueStr <- chomped |> chainUtf8

                parse tail ParsingKey [] [] (Dict.insert dict keyStr valueStr)

            ['%', secondByte, thirdByte, ..] ->
                hex = Num.toU8 (hexBytesToU32 [secondByte, thirdByte])

                parse (List.dropFirst tail 2) state key (List.append chomped hex) dict

            [firstByte, ..] -> parse tail state key (List.append chomped firstByte) dict

    parse bytes ParsingKey [] [] (Dict.empty {})

hexBytesToU32 : List U8 -> U32
hexBytesToU32 = \bytes ->
    bytes
    |> List.reverse
    |> List.walkWithIndex 0 \accum, byte, i -> accum + (Num.powInt 16 (Num.toU32 i)) * (hexToDec byte)
    |> Num.toU32

hexToDec : U8 -> U32
hexToDec = \byte ->
    when byte is
        '0' -> 0
        '1' -> 1
        '2' -> 2
        '3' -> 3
        '4' -> 4
        '5' -> 5
        '6' -> 6
        '7' -> 7
        '8' -> 8
        '9' -> 9
        'A' -> 10
        'B' -> 11
        'C' -> 12
        'D' -> 13
        'E' -> 14
        'F' -> 15
        _ -> crash "Impossible error: the `when` block I'm in should have matched before reaching the catch-all `_`."
