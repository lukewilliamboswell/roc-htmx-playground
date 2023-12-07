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
        pf.Command,
        pf.Env,
        pf.Utc,
        pf.Url.{ Url },
        html.Html.{ element, a, input, div, text, ul, li },
        html.Attribute.{ attribute, id, href, class, value },
        json.Core.{ json },
        "styles.css" as stylesCSSImport : List U8,
    ]
    provides [main] to pf

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

Page : [
    HomePage,
    TodoListPage,
]

pageData : List { page : Page, title : Str, href : Str, description : Str }
pageData = [
    { page: HomePage, title: "Home", href: "/", description: "" },
    { page: TodoListPage, title: "Todos", href: "/todo", description: "" },
]

handleReq : Str, Request -> Task Response _
handleReq = \dbPath, req ->
    when (req.method, req.url |> Url.fromStr |> urlSegments) is
        (Get, ["styles.css", ..]) -> 
            staticReponse stylesCSSImport
        (Get, ["", ..]) -> 
            htmlResponse indexPage 
            |> Task.ok
        (Get, ["contact", ..]) -> 
            getContacts 
            |> Task.map listContactView 
            |> Task.map htmlResponse 
            |> Task.onErr handleErr
        (Get, ["todo", "new", ..]) -> 
            redirect "/todo" 
            |> Task.onErr handleErr
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

    header =
        Html.header [] [
            Html.nav [class "navbar navbar-expand-lg navbar-light bg-light"] [
                div [class "container-fluid"] [
                    a [class "navbar-brand", href "/"] [text "NAVBAR"],
                    Html.button
                        [
                            class "navbar-toggler",
                            (attribute "type") "button",
                            (attribute "data-bs-toggle") "collapse",
                            (attribute "data-bs-target") "#navbarNav",
                            (attribute "aria-controls") "navbarNav",
                            (attribute "aria-expanded") "false",
                            (attribute "aria-label") "Toggle navigation",
                        ]
                        [Html.span [class "navbar-toggler-icon"] []],
                    div [class "collapse navbar-collapse", id "navbarNav"] [
                        ul [class "navbar-nav"] (
                            curr <- pageData |> List.map

                            li [class "nav-item"] [
                                a (
                                    if curr.page == page then
                                        [class "nav-link active", (attribute "aria-current") "page", href curr.href]
                                    else
                                        [class "nav-link", href curr.href]
                                )
                                [text curr.title],
                            ]
                        ),
                    ],
                ],
            ],
        ]

    Html.html [] [
        Html.head [] [
            Html.meta [(attribute "name") "viewport", Attribute.content "width=device-width, initial-scale=1"] [],
            Html.link [
                Attribute.rel "stylesheet",
                href "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css",
                Attribute.integrity "sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3",
                Attribute.crossorigin "anonymous",
            ] [],
            Html.script [
                href "https://unpkg.com/htmx.org@1.9.9",
                Attribute.integrity "sha384-QFjmbokDn2DjBjq+fM+8LUIVrAgqcNW2s0PjAxHETgRn9l4fvX31ZxDxvwQnyMOX",
                Attribute.crossorigin "anonymous",
            ] [],
            Html.script [
                href "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js",
                Attribute.integrity "sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p",
                Attribute.crossorigin "anonymous",
            ] [],
        ],
        Html.body [hxBoost "true"] (List.join [[header], children]),
    ]

Contact : Str

storedContacts : List Contact
storedContacts = ["Luke", "Joe", "Bob", "Bill", "Barry"]

getContacts : Task (List Contact) Str
getContacts = Task.ok storedContacts

listContactView : List Contact -> Html.Node
listContactView = \_ ->
    Html.h1 [] [text "TODO"]


hxBoost = attribute "hx-boost"
hxGet = attribute "hx-get"
hxTarget = attribute "hx-target"
hxPost = attribute "hx-post"

indexPage =
    layout HomePage [
        div [class "container"] [
            Html.h1 [] [text "Home Page"],
            a [class "pure-button", hxGet "/todo", hxTarget "body"] [
                text "TODOs",
            ],
        ]
    ]

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
    headerRows = 
        ["Task", "Status", ""] 
        |> List.map \col -> Html.th [(attribute "scope") "col"] [text col]

    tableRows = 
        todo <- List.map todos
        
        Html.tr [] [
            Html.td [(attribute "scope") "row"] [text todo.task],
            Html.td [] [text todo.status],
            Html.td [] [
                a [href "", hxPost "/todo/\(Num.toStr todo.id)/delete", hxTarget "body"] [
                    (element "button") [(attribute "type") "button", class "btn btn-danger"] [text "Delete"],
                ]
            ],
        ]

    layout TodoListPage [
        div [class "container"] [
            Html.h1 [] [text "Todos"],
            createTodoView,
            Html.table [class "table"] [
                Html.thead [] [ Html.tr [] headerRows],
                Html.tbody [] tableRows,
            ]
        ]
    ]

createTodoView : Html.Node
createTodoView =
    Html.form [Attribute.action "/todo/new",Attribute.method "post"][
        div [class "row g-3 align-items-center"] [
            div [class "col-auto"] [
                input [(attribute "name") "task", (attribute "type") "text", class "form-control"] [],
            ],
            # hidden form input
            input [(attribute "name") "status", value "In-Progress", (attribute "type") "text", class "d-none"] [],
            div [class "col-auto"] [
                Html.button [(attribute "type") "submit", class "btn btn-primary"] [text "Add"],
            ],
        ]
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

# STUFF TO KEEP HERE TO STOP IMPORTS FROM COMPLAINING
# STUFF TO KEEP HERE TO STOP IMPORTS FROM COMPLAINING
# STUFF TO KEEP HERE TO STOP IMPORTS FROM COMPLAINING
# STUFF TO KEEP HERE TO STOP IMPORTS FROM COMPLAINING
# STUFF TO KEEP HERE TO STOP IMPORTS FROM COMPLAINING
# STUFF TO KEEP HERE TO STOP IMPORTS FROM COMPLAINING


staticReponse : List U8 -> Task Response []
staticReponse = \body ->
    Task.ok {
        status: 200,
        headers: [
            { name: "Cache-Control", value: Str.toUtf8 "max-age=120" },
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

logRequest : Request -> Task {} *
logRequest = \req ->
    dateTime <- Utc.now |> Task.map Utc.toIso8601Str |> Task.await

    body = requestBody req |> Str.fromUtf8 |> Result.withDefault "<empty body>"

    Stdout.line "\(dateTime) \(Http.methodToStr req.method) \(req.url) \(body)"
    
urlSegments : Url -> List Str
urlSegments = \url -> url |> Url.path |> Str.split "/" |> List.dropFirst 1
    

requestBody : Request -> List U8
requestBody = \req ->
    when req.body is
        EmptyBody -> []
        Body { body } -> body
    

# lineHtml = element "line"
# strokeWidth = attribute "stroke-width"
# x1 = attribute "x1"
# y1 = attribute "y1"
# x2 = attribute "x2"
# y2 = attribute "y2"
# viewBox = attribute "viewBox"

# deleteIcon = Html.svg
#     [
#         class "svg-icon",
#         width "20",
#         height "20",
#         viewBox "0 0 100 100",
#     ]
#     [
#         lineHtml [x1 "20", y1 "20", x2 "80", y2 "80", strokeWidth "10"] [],
#         lineHtml [x1 "80", y1 "20", x2 "20", y2 "80", strokeWidth "10"] [],
#     ]


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
    