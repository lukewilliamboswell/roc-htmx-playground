module [respondHtml, decodeFormValues]

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

decodeFormValues = \body ->
    Http.parseFormUrlEncoded body
    |> Result.mapErr \BadUtf8 -> BadRequest InvalidFormEncoding
    |> Task.fromResult
