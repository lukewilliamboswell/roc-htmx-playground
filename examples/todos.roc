app "http"
    packages {
        pf: "https://github.com/roc-lang/basic-webserver/releases/download/0.2.0/J6CiEdkMp41qNdq-9L3HGoF2cFkafFlArvfU1RtR4rY.tar.br",
        html: "https://github.com/Hasnep/roc-html/releases/download/v0.2.0/5fqQTpMYIZkigkDa2rfTc92wt-P_lsa76JVXb8Qb3ms.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.5.0/jEPD_1ZLFiFrBeYKiKvHSisU-E3LZJeenfa9nvqJGeE.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Task.{ Task },
        pf.Http.{ Request, Response },
        pf.Utc,
        pf.Command,
        pf.Env,
        pf.Url.{ Url },
        html.Html.{ a, div, label, text, ul, li },
        html.Attribute.{ class },
        json.Core.{ json },
        "static/styles.css" as stylesCSSImport : List U8,
        "static/htmx-1.9.9.min.js" as htmxJSImport : List U8,
        "static/pure-3.0.0.min.css" as pureCSSImport : List U8,
    ]
    provides [main] to pf

Page : [
    HomePage, 
    SportsPage,
    TodoListPage,
]

pageData : List { page: Page, title : Str, href : Str, description : Str}
pageData =
    [
        { page: HomePage, title: "Home", href: "/", description: "" },
        { page: SportsPage, title: "Sport", href: "/sports", description: "" },
        { page: TodoListPage, title: "Todos", href: "/todo", description: "" },
    ]

handleReq : Str, Request -> Task Response _
handleReq = \dbPath, req ->
    when (req.method, req.url |> Url.fromStr |> urlSegments) is

        # Static
        (Get, ["styles.css", ..]) -> staticReponse stylesCSSImport
        (Get, ["pure-3.0.0.min.css", ..]) -> staticReponse pureCSSImport
        (Get, ["htmx-1.9.9.min.js", ..]) -> staticReponse htmxJSImport

        # Pages
        (Get, ["", ..]) -> respondHtmlCached (Html.render indexPage) 200
        (Get, ["sports", ..]) -> respondHtmlCached (Html.render sportsPage) 200
        (Get, ["contact", ..]) -> getContacts |> Task.map listContactView |> Task.map htmlResponse |> Task.onErr handleErr

        # TODOs
        (Get, ["todo", "new", ..]) -> redirect "/todo" |> Task.onErr handleErr
        (Post, ["todo", idStr, "delete", ..]) -> 
            deleteTodo dbPath idStr 
            |> Task.await \_ -> redirect "/todo"
            |> Task.onErr handleErr

        (Post, ["todo", "new", ..]) ->
            req
            |> requestBody
            |> parseTodo
            |> Task.fromResult
            |> Task.await (createTodo dbPath) # TODO if we fail to create a TODO redirect to an error??
            |> Task.await \_ -> redirect "/todo"
            |> Task.onErr handleErr

        (Get, ["todo", ..]) ->
            getTodos dbPath 
            |> Task.map todoPage 
            |> Task.map htmlResponse 
            |> Task.onErr handleErr
        (_, _) -> redirect "/" |> Task.onErr handleErr


layout : Page, List Html.Node -> Html.Node
layout = \page, children ->
    
    navLinks = 
        pageData |> List.map \curr -> menuItem curr.title curr.href (curr.page == page)

    Html.html [] [
        div [class "header"] [menu navLinks],
        head,
        Html.body [hxBoost "true"] [
            div [class "content"] children
        ],
    ]

staticReponse : List U8 -> Task Response []
staticReponse = \body ->
    Task.ok { 
        status: 200, 
        headers: [
            { name: "Cache-Control", value: Str.toUtf8 "max-age=120" }
        ], 
        body,
    }

htmlResponse : Html.Node -> Response
htmlResponse = \node -> {
    status: 200,
    headers: [
        { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
    ],
    body: Str.toUtf8 (Html.render node),
}

redirect : Str -> Task Response Str
redirect = \next ->
    Task.ok {
        status: 303,
        headers: [
            { name: "Location", value: Str.toUtf8 next },
        ],
        body: [],
    }

handleErr : Str -> Task Response []
handleErr = \msg ->
    Task.ok {
        status: 500,
        headers: [
            { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
        ],
        body: Str.toUtf8 msg,
    }

Contact : Str

storedContacts : List Contact
storedContacts = ["Luke", "Joe", "Bob", "Bill", "Barry"]

getContacts : Task (List Contact) Str
getContacts = Task.ok storedContacts

listContactView : List Contact -> Html.Node
listContactView = \contacts ->
    table
        ["Name"]
        (
            name <- contacts |> List.map

            [text name]
        )

logRequest : Request -> Task {} *
logRequest = \req ->
    dateTime <- Utc.now |> Task.map Utc.toIso8601Str |> Task.await

    body = requestBody req |> Str.fromUtf8 |> Result.withDefault "<empty body>"

    Stdout.line "\(dateTime) \(Http.methodToStr req.method) \(req.url) \(body)"

respondHtmlCached : Str, U16 -> Task Response *
respondHtmlCached = \body, code ->
    Task.ok {
        status: code,
        headers: [
            { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
            { name: "Cache-Control", value: Str.toUtf8 "max-age=120" },
        ],
        body: Str.toUtf8 body,
    }

urlSegments : Url -> List Str
urlSegments = \url -> url |> Url.path |> Str.split "/" |> List.dropFirst 1

stylesCSS = Html.link [Attribute.rel "stylesheet", Attribute.href "/styles.css"] []
pureCSS = Html.link [Attribute.rel "stylesheet", Attribute.href "/pure-3.0.0.min.css"] []
meta = Html.meta [Attribute.name "viewport", Attribute.content "width=device-width, initial-scale=1"] []
head = Html.head [] [meta, stylesCSS, pureCSS, htmxJS]
htmxJS = Html.script [Attribute.src "/htmx-1.9.9.min.js"] []

hxBoost = Attribute.attribute "hx-boost"
hxGet = Attribute.attribute "hx-get"
hxTarget = Attribute.attribute "hx-target"
hxPost = Attribute.attribute "hx-post"

indexPage =
    layout HomePage [
        Html.h1 [] [text "Home Page"],
        a [class "pure-button", hxGet "/todo", hxTarget "body"] [
            text "TODOs",
        ],
    ]

sportsPage =
    layout SportsPage [
        Html.h1 [] [text "Sports Page"],
    ]

menuItem = \title, href, isSelected ->
    li
        [
            if isSelected then class "pure-menu-item pure-menu-selected" else class "pure-menu-item",
        ]
        [
            a [Attribute.href href, class "pure-menu-link"] [text title],
        ]

menu = \children ->
    div [class "pure-menu pure-menu-horizontal"] [
        ul [class "pure-menu-list"] children,
    ]

# {"id":1,"task":"Prepare for AoC","status":"completed"}
Todo : {
    id : U64,
    task : Str,
    status : Str,
}

getTodos : Str -> Task (List Todo) Str
getTodos = \dbPath ->
    output <-
        Command.new "sqlite3"
        |> Command.arg dbPath
        |> Command.arg ".mode json"
        |> Command.arg "SELECT id, task, status FROM todos;"
        |> Command.output
        |> Task.await

    if output.status != Ok {} then
        Task.err "unable to get TODOs from \(dbPath)"
    else
        when Decode.fromBytes output.stdout json is
            Ok todos -> Task.ok todos
            Err _ -> Task.err "unable to decode todos"

todoPage : List Todo -> Html.Node
todoPage = \todos ->
    layout TodoListPage [
        Html.h1 [] [text "All the things Todo"],
        createTodoView,
        table
            ["ID", "Task", "Status", "Delete"]
            (
                todo <- todos |> List.map

                idStr = Num.toStr todo.id

                [
                    text idStr, 
                    text todo.task, 
                    text todo.status,
                    Html.button [ 
                        class "pure-button pure-button-secondary",
                        hxPost "/todo/\(idStr)/delete", 
                        hxTarget "body",
                    ] [ text "Delete" ],
                ]
            ),
    ]

createTodoView : Html.Node
createTodoView =
    Html.form
        [
            class "pure-form",
            Attribute.action "/todo/new",
            Attribute.method "post",
        ]
        [
            Html.fieldset [] [
                div [class "pure-g"] [
                    div [class "pure-u-1"] [
                        label [Attribute.for "task"] [text "Task"],
                        Html.input [Attribute.name "task", Attribute.type "text", Attribute.placeholder "Task", class "pure-u-23-24"] [],  
                    ],
                    div [class "pure-u-1"] [
                        label [Attribute.for "status"] [text "Status"],
                        Html.input [Attribute.name "status", Attribute.type "text", Attribute.placeholder "Status", class "pure-u-23-24"] [],
                    ],
                    div [class "pure-u-1"] [
                        Html.button [ Attribute.type "submit", class "pure-button pure-button-primary"] [ text "Add" ],        
                    ],
                ],
            ],
        ]

createTodo : Str -> (Todo -> Task {} Str)
createTodo = \dbPath -> \{ task, status } ->
        output <-
            Command.new "sqlite3"
            |> Command.arg dbPath
            |> Command.arg ".mode json"
            |> Command.arg "INSERT INTO todos (task, status) VALUES ('\(task)', '\(status)');"
            |> Command.arg "SELECT id, task, status FROM todos WHERE id = last_insert_rowid();"
            |> Command.output
            |> Task.await

        when output.status is
            Ok {} ->
                {} <- Stdout.line "TODO CREATED" |> Task.await
                Task.ok {}

            Err _ -> Task.err "unable to insert TODO into \(dbPath)"

deleteTodo : Str, Str -> Task {} Str
deleteTodo = \dbPath, idStr ->
    output <-
        Command.new "sqlite3"
        |> Command.arg dbPath
        |> Command.arg ".mode json"
        |> Command.arg "DELETE FROM todos WHERE id = \(idStr);"
        |> Command.output
        |> Task.await

    when output.status is
        Ok {} ->
            {} <- Stdout.line "TODO DELETED" |> Task.await
            Task.ok {}

        Err _ -> Task.err "unable to delete TODO from \(dbPath) with ID \(idStr)"

# getTodoFromQuery : Str -> Task Todo Str
# getTodoFromQuery = \url ->
#     params = url |> Url.fromStr |> Url.queryParams

#     when (params |> Dict.get "task", params |> Dict.get "status") is
#         (Ok task, Ok status) -> Task.ok { id: 0, task: Str.replaceEach task "%20" " ", status: Str.replaceEach status "%20" " " }
#         _ -> Task.err "invalid query expected ?task=foo&status=bar got \(url)"

parseTodo : List U8 -> Result Todo Str
parseTodo = \bytes ->
    dict = parseFormUrlEncoded bytes

    task <-
        Dict.get dict "task"
        |> Result.mapErr \_ -> "unable to parse \"task\" from body"
        |> Result.try

    status <-
        Dict.get dict "status"
        |> Result.mapErr \_ -> "unable to parse \"task\" from body"
        |> Result.try

    Ok { id: 0, task, status }

table : List Str, List (List Html.Node) -> Html.Node
table = \headerCols, rows ->
    Html.table [class "pure-table"] [
        Html.thead [] [
            Html.tr [] (headerCols |> List.map \col -> Html.th [] [text col]),
        ],
        Html.tbody
            []
            (
                row <- List.map rows

                Html.tr
                    []
                    (
                        col <- List.map row

                        Html.td [] [col]
                    )
            ),
    ]

requestBody : Request -> List U8
requestBody = \req ->
    when req.body is
        EmptyBody -> []
        Body { body } -> body

parseFormUrlEncoded : List U8 -> Dict Str Str
parseFormUrlEncoded = \bytes ->
    go = \bytesRemaining, state, key, chomped, dict ->
        next = List.dropFirst bytesRemaining 1
        when bytesRemaining is
            [] if List.isEmpty chomped -> dict
            [] ->
                # chomped last value
                keyStr = key |> Str.fromUtf8 |> unwrap
                valueStr = chomped |> Str.fromUtf8 |> unwrap

                Dict.insert dict keyStr valueStr

            ['=', ..] -> go next ParsingValue chomped [] dict # put chomped into key
            ['&', ..] ->
                keyStr = key |> Str.fromUtf8 |> unwrap
                valueStr = chomped |> Str.fromUtf8 |> unwrap

                go next ParsingKey [] [] (Dict.insert dict keyStr valueStr)

            ['%', firstByte, secondByte, ..] ->
                hex = Num.toU8 (hexBytesToU32 [firstByte, secondByte])

                go (List.dropFirst next 2) state key (List.append chomped hex) dict

            [first, ..] -> go next state key (List.append chomped first) dict

    go bytes ParsingKey [] [] (Dict.empty {})

expect hexBytesToU32 ['2', '0'] == 32
expect
    Str.toUtf8 "task=asdfsadf&status=qwerwe"
    |> parseFormUrlEncoded
    |> Dict.toList
    |> Bool.isEq [("task", "asdfsadf"), ("status", "qwerwe")]

expect
    Str.toUtf8 "task=asdfs%20adf&status=qwerwe"
    |> parseFormUrlEncoded
    |> Dict.toList
    |> Bool.isEq [("task", "asdfs adf"), ("status", "qwerwe")]

unwrap = \thing ->
    when thing is
        Ok unwrapped -> unwrapped
        Err _ -> crash "unable to unwrap thing"

hexBytesToU32 : List U8 -> U32
hexBytesToU32 = \bytes ->
    bytes
    |> List.reverse
    |> List.walkWithIndex 0 \accum, byte, i -> accum + (Num.powInt 16 (Num.toU32 i)) * (hexToDec byte)
    |> Num.toU32

expect hexBytesToU32 ['0', '0', '0', '0'] == 0
expect hexBytesToU32 ['0', '0', '0', '1'] == 1
expect hexBytesToU32 ['0', '0', '0', 'F'] == 15
expect hexBytesToU32 ['0', '0', '1', '0'] == 16
expect hexBytesToU32 ['0', '0', 'F', 'F'] == 255
expect hexBytesToU32 ['0', '1', '0', '0'] == 256
expect hexBytesToU32 ['0', 'F', 'F', 'F'] == 4095
expect hexBytesToU32 ['1', '0', '0', '0'] == 4096
expect hexBytesToU32 ['1', '6', 'F', 'F', '1'] == 94193

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
        _ -> 0

expect hexToDec '0' == 0
expect hexToDec 'F' == 15


main : Request -> Task Response []
main = \req ->

    # Log the date, time, method, and url to stdout
    {} <- logRequest req |> Task.await

    # Read DB_PATH environment variable
    dbPath <-
        Env.var "DB_PATH"
        |> Task.onErr \_ -> crash "unable to read DB_PATH environment variable"
        |> Task.await

    # Handle request
    handleReq dbPath req
