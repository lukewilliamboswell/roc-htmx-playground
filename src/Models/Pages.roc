module [
    BigTaskPage,
    defaultBigTaskPage,
]

BigTaskPage : {
    page: U64,
    items: U64,
    sorted: Str,
}

defaultBigTaskPage = {
    page: 1,
    items: 25,
    sorted: "",
}
