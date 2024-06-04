module [
    respondHtml,
    decodeFormValues,
    parseQueryParams,
    parsePagedParams,
]

import pf.Task exposing [Task]
import pf.Http exposing [Response]
import html.Html

respondHtml : Html.Node -> Task Response []_
respondHtml = \node ->
    Task.ok {
        status: 200,
        headers: [
            { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
        ],
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
        _ -> Err InvalidQuery

parsePagedParams : Dict Str Str -> Result {page: I64, count: I64} _
parsePagedParams = \queryParams ->

    maybePage = queryParams |> Dict.get "page" |> Result.try Str.toI64
    maybeCount = queryParams |> Dict.get "count" |> Result.try Str.toI64

    when (maybePage, maybeCount) is
        (Ok page, Ok count) -> Ok { page, count }
        _ -> Err InvalidPagedParams

expect
    "/bigTask?page=22&count=33"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Ok {page:22, count: 33}

expect
    "/bigTask?page=0&items=33"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Err InvalidPagedParams

expect
    "/bigTask"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Err InvalidQuery
