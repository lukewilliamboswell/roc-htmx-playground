module [
    Todo,
    emptyTodo,
]

Todo : {
    id : I64,
    task : Str,
    status : Str,
}

emptyTodo = {
    id: 0,
    task: "",
    status: "Not Started",
}
