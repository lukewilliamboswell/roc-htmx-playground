module [
    respond_redirect,
    respond_html,
    decode_form_values,
    parse_query_params,
    query_params_to_url,
    parse_paged_params,
]

import pf.Http exposing [Response]
import pf.MultipartFormData
import html.Html

respond_redirect : Str -> Result Response []_
respond_redirect = \next ->
    Ok {
        status: 303,
        headers: [
            { name: "Location", value: next },
        ],
        body: [],
    }

respond_html : Html.Node, List { name : Str, value : Str } -> Result Response []_
respond_html = \node, other_headers ->
    Ok {
        status: 200,
        headers: [
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ]
            |> List.concat other_headers,
        body: Str.to_utf8 (Html.render node),
    }

decode_form_values : List U8 -> Result (Dict Str Str) _
decode_form_values = \body ->
    MultipartFormData.parse_form_url_encoded body
    |> Result.map_err \BadUtf8 -> BadRequest InvalidFormEncoding

parse_query_params : Str -> Result (Dict Str Str) _
parse_query_params = \url ->
    when Str.split_on url "?" is
        [_, query_part] -> query_part |> Str.to_utf8 |> MultipartFormData.parse_form_url_encoded
        parts -> Err (InvalidQuery (Inspect.to_str parts))

query_params_to_url : Dict Str Str -> Str
query_params_to_url = \params ->
    Dict.to_list params
    |> List.map \(k, v) -> "$(k)=$(v)"
    |> Str.join_with "&"

expect
    "localhost:8000?port=8000&name=Luke"
    |> parse_query_params
    |> Result.map_ok query_params_to_url
    ==
    Ok "port=8000&name=Luke"

parse_paged_params : Dict Str Str -> Result { page : I64, items : I64 } _
parse_paged_params = \query_params ->
    maybe_page = query_params |> Dict.get "page" |> Result.try Str.to_i64
    maybe_count = query_params |> Dict.get "items" |> Result.try Str.to_i64

    when (maybe_page, maybe_count) is
        (Ok page, Ok items) if page >= 1 && items > 0 -> Ok { page, items }
        _ -> Err InvalidPagedParams

expect
    "/bigTask?page=22&items=33"
    |> parse_query_params
    |> Result.try parse_paged_params
    ==
    Ok { page: 22, items: 33 }

expect
    "/bigTask?page=0&count=33"
    |> parse_query_params
    |> Result.try parse_paged_params
    ==
    Err InvalidPagedParams

expect
    "/bigTask"
    |> parse_query_params
    |> Result.try parse_paged_params
    ==
    Err (InvalidQuery "[\"/bigTask\"]")
