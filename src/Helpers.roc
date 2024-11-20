module [
    respondRedirect,
    respondHtml,
    decodeFormValues,
    parseQueryParams,
    queryParamsToUrl,
    parsePagedParams,
]

import pf.Http exposing [Response]
import html.Html

respondRedirect : Str -> Task Response []_
respondRedirect = \next ->
    Task.ok {
        status: 303u16,
        headers: [
            { name: "Location", value: next },
        ],
        body: [],
    }

respondHtml : Html.Node, List {name: Str, value : Str} -> Task Response []_
respondHtml = \node, otherHeaders ->
    Task.ok {
        status: 200u16,
        headers:  [
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ]
        |> List.concat otherHeaders,
        body: Str.toUtf8 (Html.render node),
    }

decodeFormValues : List U8 -> Task (Dict Str Str) _
decodeFormValues = \body ->
    Http.parseFormUrlEncoded body
    |> Result.mapErr \BadUtf8 -> BadRequest InvalidFormEncoding
    |> Task.fromResult

parseQueryParams : Str -> Result (Dict Str Str) _
parseQueryParams = \url ->
    when Str.split url "?" is
        [_, queryPart] -> queryPart |> Str.toUtf8 |> Http.parseFormUrlEncoded
        parts -> Err (InvalidQuery (Inspect.toStr parts))

queryParamsToUrl : Dict Str Str -> Str
queryParamsToUrl = \params ->
    Dict.toList params
    |> List.map \(k,v) ->"$(k)=$(v)"
    |> Str.joinWith "&"

expect
    "localhost:8000?port=8000&name=Luke"
    |> parseQueryParams
    |> Result.map queryParamsToUrl
    ==
    Ok "port=8000&name=Luke"

parsePagedParams : Dict Str Str -> Result {page: I64, items: I64} _
parsePagedParams = \queryParams ->

    maybePage = queryParams |> Dict.get "page" |> Result.try Str.toI64
    maybeCount = queryParams |> Dict.get "items" |> Result.try Str.toI64

    when (maybePage, maybeCount) is
        (Ok page, Ok items) if page >= 1 && items > 0 -> Ok { page, items }
        _ -> Err InvalidPagedParams

expect
    "/bigTask?page=22&items=33"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Ok {page:22, items: 33}

expect
    "/bigTask?page=0&count=33"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Err InvalidPagedParams

expect
    "/bigTask"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Err (InvalidQuery "[\"/bigTask\"]")
