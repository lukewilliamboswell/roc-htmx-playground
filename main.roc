app "http"
    packages {
        pf: "https://github.com/roc-lang/basic-webserver/releases/download/0.2.0/J6CiEdkMp41qNdq-9L3HGoF2cFkafFlArvfU1RtR4rY.tar.br",
        html: "https://github.com/Hasnep/roc-html/releases/download/v0.2.0/5fqQTpMYIZkigkDa2rfTc92wt-P_lsa76JVXb8Qb3ms.tar.br",
        json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.5.0/jEPD_1ZLFiFrBeYKiKvHSisU-E3LZJeenfa9nvqJGeE.tar.br",
        ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.1.1/cPHdNPNh8bjOrlOgfSaGBJDz6VleQwsPdW0LJK6dbGQ.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Task.{ Task },
        pf.Http.{ Request, Response },
        pf.Command,
        pf.Env,
        pf.Utc,
        pf.Url.{ Url },
        html.Html.{ header, table, thead, form, tbody, h5, td, th, tr, nav, meta, nav, button, span, link, body, button, a, input, div, text, ul, li, label },
        html.Attribute.{ src, id, href, rel, name, integrity, crossorigin, action, method, class, value, role, for },
        json.Core.{ json },
        ansi.Color,
        "styles.css" as stylesFile : List U8,
        "site.js" as siteFile : List U8,
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

    # Session cookie should be sent with each request, otherwise create one
    when getSessionId req is 
        Ok sessionId -> handleReq (Guest sessionId) dbPath req |> Task.onErr handleErr
        Err _ ->
            result <- newSessionId dbPath |> Task.attempt

            when result is 
                Err err -> handleErr err
                Ok sessionId -> 
                    
                    Task.ok {
                        status: 303,
                        headers: [
                            { name: "Set-Cookie", value: Str.toUtf8 "sessionId=\(Num.toStr sessionId)" },
                            { name: "Location", value: Str.toUtf8 req.url },
                        ],
                        body: [],
                    }

Session : [
    User Str U64, 
    Guest U64,
]

Page : [
    HomePage,
    TaskListPage,
    LoginPage,
]

pageData : List { page : Page, title : Str, href : Str, description : Str }
pageData = [
    { page: HomePage, title: "Home", href: "/", description: "The home page" },
    { page: TaskListPage, title: "Tasks", href: "/task", description: "Manage tasks" },
    { page: LoginPage, title: "Login", href: "/login", description: "Log in" },
]

handleReq : Session, Str, Request -> Task Response _
handleReq = \session, dbPath, req ->
    when (req.method, req.url |> Url.fromStr |> urlSegments) is
        (Get, [""]) -> indexPage |> htmlResponse |> Task.ok
        (Get, ["robots.txt"]) -> staticReponse robotsTxt
        (Get, ["styles.css"]) -> staticReponse stylesFile
        (Get, ["site.js"]) -> staticReponse siteFile
        (Get, ["contact"]) -> 

            contacts <- getContacts |> Task.map 

            contacts |> listContactView |> htmlResponse 

        (Post, ["login"]) ->

            params = parseFormUrlEncoded (parseBody req) 
        
            dbg params

            Task.err (LoginPostUnimplemented)

        (Get, ["login"]) -> 

            loginPage |> htmlResponse |> Task.ok
         
        (Get, ["task", "new"]) -> redirect "/task" 
        (Post, ["task", idStr, "delete"]) ->

            {} <- deleteAppTask dbPath idStr |> Task.await

            tasks <- getAppTasks dbPath ""  |> Task.await

            listTaskView tasks "" |> htmlResponse |> Task.ok            

        (Post, ["task", "search"]) ->
            params = parseFormUrlEncoded (parseBody req) 

            filterTasksQuery = Dict.get params "filterTasks" |> Result.withDefault ""

            tasks <- getAppTasks dbPath filterTasksQuery  |> Task.await

            listTaskView tasks filterTasksQuery |> htmlResponse |> Task.ok            
            
        (Post, ["task", "new"]) ->

            task <- parseBody req |> parseAppTask |> Task.fromResult |> Task.await 
            
            createAppTask dbPath task |> Task.attempt \result -> 
                when result is 
                    Ok {} -> redirect "/task"
                    Err TaskWasEmpty -> redirect "/task"
                    Err err -> handleErr err

        (Get, ["task"]) ->

            tasks <- getAppTasks dbPath "" |> Task.await
            
            taskPage tasks "" |> htmlResponse |> Task.ok

        _ -> Task.err (URLNotFound req.url)

layout : Page, List Html.Node -> Html.Node
layout = \page, children ->

    {description, title} = 
        pageData 
        |> List.keepIf \curr -> curr.page == page
        |> List.first 
        |> unwrap "unable to get page from pageData"

    Html.html [(attr "lang") "en",  (attr "data-bs-theme") "auto"] [
        Html.head [] [
            (el "title") [] [text title],
            meta [(attr "charset") "UTF-8"] [],
            meta [name "description", (attr "content") description] [],
            meta [name "viewport", (attr "content") "width=device-width, initial-scale=1"] [],
            link [
                rel "stylesheet",
                href "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css",
                integrity "sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN",
                crossorigin "anonymous",
            ] [],
            link [
                rel "stylesheet",
                href "/styles.css",
            ] [],
            # The scripts are here to prevent these being loaded each time htmx swaps content of the body
            (el "script") [
                src "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js",
                integrity "sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL",
                crossorigin "anonymous",
            ] [],
            (el "script") [
                src "https://unpkg.com/htmx.org@1.9.9",
                integrity "sha384-QFjmbokDn2DjBjq+fM+8LUIVrAgqcNW2s0PjAxHETgRn9l4fvX31ZxDxvwQnyMOX",
                crossorigin "anonymous",
            ] [],
            (el "script") [
                src "/site.js",
            ] [],
        ],
        body [hxBoost "true"] [
            header [] [
                nav [class "navbar navbar-expand-md mb-5"] [
                    div [class "container-fluid"] [
                        a [class "navbar-brand", href "/"] [text "DEMO"],
                        button
                            [
                                class "navbar-toggler",
                                (attr "type") "button",
                                (attr "data-bs-toggle") "collapse",
                                (attr "data-bs-target") "#navbarNav",
                                (attr "aria-controls") "navbarNav",
                                (attr "aria-expanded") "false",
                                (attr "aria-label") "Toggle navigation",
                            ]
                            [span [class "navbar-toggler-icon"] []],
                        div [class "collapse navbar-collapse", id "navbarNav"] [
                            ul [class "navbar-nav"] (
                                curr <- pageData |> List.map
    
                                li [class "nav-item"] [
                                    a (
                                        if curr.page == page then
                                            [class "nav-link active", 
                                            (attr "aria-current") "page", 
                                            href curr.href,
                                            hxPushUrl "true",
                                        ]
                                        else
                                            [class "nav-link", 
                                            href curr.href,
                                            hxPushUrl "true",
                                        ]
                                    )
                                    [text curr.title],
                                ]
                            ),
                        ],
                    ],
                ],
            ],
            (el "main") [] children, 
        ],
    ]

Contact : Str

storedContacts : List Contact
storedContacts = ["Luke", "Joe", "Bob", "Bill", "Barry"]

getContacts : Task (List Contact) []_
getContacts = Task.ok storedContacts

listContactView : List Contact -> Html.Node
listContactView = \_ ->
    Html.h1 [] [text "TODO"]


hxBoost = attr "hx-boost"
hxGet = attr "hx-get"
hxTarget = attr "hx-target"
hxPost = attr "hx-post"
hxPushUrl = attr "hx-push-url"
hxTrigger = attr "hx-trigger"

indexPage =
    layout HomePage [
        div [class "container"] [
            (el "button") [
                (attr "type") "button", 
                class "btn btn-secondary mt-2",
                hxGet "/task",
                hxTarget "body",
            ] [text "Manage Tasks"],
        ]
    ]

loginPage : Html.Node
loginPage =
    layout LoginPage [
        div [class "container"] [
            div [class "row justify-content-center"] [
                div [class "col-md-6 card"] [
                    div [class "card-body"] [
                        h5 [ class "card-title"] [ text "Login Form"],
                        form [class "container-fluid", action "/login", method "post"] [
                            div [class "col-auto"] [
                                label [class "col-form-label", for "loginUsername"] [text "Username"]
                            ],
                            div [class "col-auto"] [
                                input [class "form-control", (attr "type") "username", (attr "required") "", id "loginUsername", name "user"] []
                            ],
                            div [class "col-auto"] [
                                label [class "col-form-label", for "loginPassword"] [text "Password (not used)"]
                            ],
                            div [class "col-auto"] [
                                input [class "form-control disabled", (attr "type") "password", (attr "disabled") "", id "loginPassword", name "pass"] []
                            ],
                            div [class "col-auto mt-2"] [
                                button [(attr "type") "submit", (attr "type") "button", class "btn btn-primary"] [text "Submit"]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]

AppTask : {
    id : U64,
    task : Str,
    status : Str,
}

getAppTasks : Str, Str -> Task (List AppTask) [SqliteErrorGetTask _, UnableToDecodeTask _]_
getAppTasks = \dbPath, filterQuery ->

    escapeSQL = \str -> Str.replaceEach str "'" "''"

    sql = 
        if Str.isEmpty filterQuery then 
            "SELECT id, task, status FROM tasks;"
        else
            "SELECT id, task, status FROM tasks WHERE task LIKE '%\(escapeSQL filterQuery)%';" 
    
    output <-
        Command.new "sqlite3"
        |> Command.arg dbPath
        |> Command.arg ".mode json"
        |> Command.arg sql
        |> Command.output
        |> Task.await

    if output.status != Ok {} then
        Task.err (SqliteErrorGetTask output.stderr)
    else if List.isEmpty output.stdout then
        Task.ok []
    else
        when Decode.fromBytes output.stdout json is
            Ok tasks -> Task.ok tasks
            Err _ -> Task.err (UnableToDecodeTask output.stdout)

taskPage : List AppTask, Str -> Html.Node
taskPage = \tasks, taskQuery ->
    layout TaskListPage [
        div [class "container-fluid"] [
            div [class "row justify-content-center"] [
                div [class "col-md-9"] [
                    createAppTaskView,
                    input [
                        class "form-control mt-2",
                        name "filterTasks", 
                        (attr "type") "text", 
                        (attr "placeholder") "Search",
                        (attr "type") "text",
                        value taskQuery,
                        name "taskSearch",
                        hxPost "/task/search",
                        hxTrigger "input changed delay:500ms, search",
                        hxTarget "#taskTable",
                        if Str.isEmpty taskQuery then (id "nothing") else (attr "autofocus") "",
                    ] [],
                    listTaskView tasks taskQuery,
                ]
            ]
        ]
    ]

listTaskView : List AppTask, Str -> Html.Node 
listTaskView = \tasks, taskQuery -> 
    if List.isEmpty tasks && Str.isEmpty taskQuery  then 
        div [class "alert alert-info mt-2", role "alert"] [ text "Nil tasks, add a task to get started." ]
    else if List.isEmpty tasks  then 
        div [class "alert alert-info mt-2", role "alert"] [ text "There are Nil tasks matching your query." ]
    else 

        tableRows = List.map tasks \task ->
                
            tr [] [
                td [(attr "scope") "row", class "col-6"] [text task.task],
                td [class "col-3 text-nowrap"] [text task.status],
                td [class "col-3"] [
                    div [class "d-flex justify-content-center"] [
                        a [ 
                            href "", 
                            hxPost "/task/\(Num.toStr task.id)/delete", 
                            hxTarget "#taskTable",
                            (attr "aria-label") "delete task",
                            (attr "style") "float: center;",
                        ] [
                            (el "button") [
                                (attr "type") "button", 
                                class "btn btn-danger",
                            ] [text "Delete"],
                        ]
                    ],
                ],
            ]

        table [
            id "taskTable",
            class "table table-striped table-hover table-sm mt-2",
        ] [
            thead [] [
                tr [] [
                    th [(attr "scope") "col", class "col-6"] [text "Task"],
                    th [(attr "scope") "col", class "col-3", (attr "rowspan") "2"] [text "Status"],
                ]
            ],
            tbody [] tableRows,
        ]
            
createAppTaskView : Html.Node
createAppTaskView = 
    form [action "/task/new", method "post"][
        div [class "input-group mb-3"] [
            input [
                id "task", 
                name "task", 
                (attr "type") "text", 
                class "form-control",
                (attr "placeholder") "Describe a new task",
                (attr "required") "",
            ] [],
            label [for "task", class "d-none"] [text "input the task description"],
            input [name "status", value "In-Progress", (attr "type") "text", class "d-none"] [], # hidden form input
            button [(attr "type") "submit", class "btn btn-primary"] [text "Add"],
        ]
    ]

createAppTask : Str, AppTask -> Task {} [TaskWasEmpty, SqliteErrorCreatingTask _]_
createAppTask = \dbPath, { task, status } ->
    if Str.isEmpty task then 
        Task.err TaskWasEmpty
    else 
        output <-
            Command.new "sqlite3"
            |> Command.arg dbPath
            |> Command.arg ".mode json"
            |> Command.arg "INSERT INTO tasks (task, status) VALUES ('\(task)', '\(status)');"
            |> Command.arg "SELECT id, task, status FROM tasks WHERE id = last_insert_rowid();"
            |> Command.output
            |> Task.await

        when output.status is
            Ok {} -> Task.ok {}
            Err msg -> Task.err (SqliteErrorCreatingTask msg)

deleteAppTask : Str, Str -> Task {} [SqliteErrorDeletingTask _]_
deleteAppTask = \dbPath, idStr ->
    output <-
        Command.new "sqlite3"
        |> Command.arg dbPath
        |> Command.arg ".mode json"
        |> Command.arg "DELETE FROM tasks WHERE id = \(idStr);"
        |> Command.output
        |> Task.await

    when output.status is
        Ok {} -> Task.ok {}
        Err _ -> Task.err (SqliteErrorDeletingTask output.stderr)


newSessionId : Str -> Task U64 [SqliteErrorDeletingTask _, UnableToParseSessionId _]_
newSessionId = \dbPath -> 

    query = 
        """
        BEGIN TRANSACTION;
        insert into sessions (id) values (abs(random()));
        select last_insert_rowid();
        COMMIT;
        """

    output <-
        Command.new "sqlite3"
        |> Command.arg dbPath
        |> Command.arg query
        |> Command.output
        |> Task.await

    when output.status is
        Ok {} -> 
            output.stdout
            |> Str.fromUtf8
            |> Result.map Str.trim
            |> Result.try Str.toU64
            |> Result.mapErr UnableToParseSessionId
            |> Task.fromResult
        Err _ -> Task.err (SqliteErrorDeletingTask output.stderr)

getSessionId : Request -> Result U64 [CookieNotFound, InvalidSessionId _]_
getSessionId = \req ->
    req.headers 
    |> List.keepIf \reqHeader -> reqHeader.name == "cookie"
    |> List.first
    |> Result.mapErr \_ -> CookieNotFound
    |> Result.try \reqHeader -> 
        reqHeader.value
        |> Str.fromUtf8
        |> Result.try \str -> str |> Str.split "=" |> List.get 1 
        |> Result.try Str.toU64
        |> Result.mapErr \_ -> InvalidSessionId reqHeader.value

parseAppTask : List U8 -> Result AppTask [UnableToParseBodyTask _]_
parseAppTask = \bytes ->
    dict = parseFormUrlEncoded bytes

    task <-
        Dict.get dict "task"
        |> Result.mapErr \_ -> UnableToParseBodyTask bytes
        |> Result.try

    status <-
        Dict.get dict "status"
        |> Result.mapErr \_ -> UnableToParseBodyTask bytes
        |> Result.try

    Ok { id: 0, task, status }

# STUFF I AM THINKING OF MOVING TO ANOTHER MODULE SOMETIME
# STUFF I AM THINKING OF MOVING TO ANOTHER MODULE SOMETIME
# STUFF I AM THINKING OF MOVING TO ANOTHER MODULE SOMETIME
# STUFF I AM THINKING OF MOVING TO ANOTHER MODULE SOMETIME
# STUFF I AM THINKING OF MOVING TO ANOTHER MODULE SOMETIME
# STUFF I AM THINKING OF MOVING TO ANOTHER MODULE SOMETIME

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

    (msg, code) = when err is 
        URLNotFound url -> (Str.joinWith ["404 NotFound" |> Color.fg Blue, url] " ", 404)
        _ -> (Str.joinWith ["SERVER ERROR" |> Color.fg Red,Inspect.toStr err] " ", 500) 
         

    {} <- Stderr.line msg |> Task.await

    Task.ok {
        status: code,
        headers: [],
        body: [],
    }

logRequest : Request -> Task {} *
logRequest = \req ->
    dateTime <- Utc.now |> Task.map Utc.toIso8601Str |> Task.await

    reqBody = parseBody req |> Str.fromUtf8 |> Result.withDefault "<empty body>"

    Stdout.line "\(dateTime) \(Http.methodToStr req.method) \(req.url) \(reqBody)"
    
urlSegments : Url -> List Str
urlSegments = \url -> url |> Url.path |> Str.split "/" |> List.dropFirst 1

parseBody : Request -> List U8
parseBody = \req ->
    when req.body is
        EmptyBody -> []
        Body internal -> internal.body
    

# lineHtml = el "line"
# strokeWidth = attr "stroke-width"
# x1 = attr "x1"
# y1 = attr "y1"
# x2 = attr "x2"
# y2 = attr "y2"
# viewBox = attr "viewBox"

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
                keyStr = key |> Str.fromUtf8 |> unwrap "chomped invalid utf8 key"
                valueStr = chomped |> Str.fromUtf8 |> unwrap "chomped invalid utf8 value"

                Dict.insert dict keyStr valueStr

            ['=', ..] -> go next ParsingValue chomped [] dict # put chomped into key
            ['&', ..] ->
                keyStr = key |> Str.fromUtf8 |> unwrap "chomped invalid utf8 key"
                valueStr = chomped |> Str.fromUtf8 |> unwrap "chomped invalid utf8 value"

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

unwrap = \thing, msg ->
    when thing is
        Ok unwrapped -> unwrapped
        Err _ -> crash "CRASHED \(msg)"

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

robotsTxt : List U8
robotsTxt = 
    """
    User-agent: *
    Disallow: /
    """
    |> Str.toUtf8

el = Html.element
attr = Attribute.attribute