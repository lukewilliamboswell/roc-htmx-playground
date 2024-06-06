module [
    respondHtml,
    decodeFormValues,
    parseQueryParams,
    parsePagedParams,
    paginationLinks,
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
        parts -> Err (InvalidQuery (Inspect.toStr parts))

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

# items is the number of items per page
# page is the current page
# page is 1-indexed
paginationLinks : {page : I64, items : I64, total : I64, baseHref : Str} -> List {
    disabled : Bool,
    active : Bool,
    href : Str,
    label : Str,
}
paginationLinks = \{page, items, total, baseHref} ->

    totalPages = Num.ceiling ((Num.toFrac total) / (Num.toFrac items)) |> Num.toI64

    # Previous
    prev = {
        disabled: page == 1,
        active: Bool.false,
        href: if page == 1 then "#" else "$(baseHref)page=$(Num.toStr (page - 1))&items=$(Num.toStr items)",
        label: "Previous",
    }

    # Numbered  -3 -2 -1 current +1 +2 +3
    numbered =
        List.range {
                start: At (Num.max 1 (page - 3)),
                end: At (Num.min totalPages (page + 3)),
            }
        |> List.map \n -> {
            disabled: Bool.false,
            active: n == page,
            href: if n == page then "#" else "$(baseHref)page=$(Num.toStr n)&items=$(Num.toStr items)",
            label: Num.toStr n,
        }

    # Current
    current = {
        disabled: Bool.false,
        active: Bool.true,
        href: "#",
        label: Num.toStr page,
    }

    # Next
    next = {
        disabled: page == totalPages,
        active: Bool.false,
        href: if page == totalPages then "#" else "$(baseHref)page=$(Num.toStr (page + 1))&items=$(Num.toStr items)",
        label: "Next",
    }

    if totalPages <= 7 then
        numbered
    else
        [prev,current,next]
