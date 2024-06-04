module [
    Session,
    Todo,
    User,
    Tree,
    NestedSet,
    BigTask,
    Date,
    Status,
    Priority,
    emptyTodo,
    nestedSetToTree,
    parseDate,
    parseStatus,
    parsePriority,
    dateToStr,
    priorityToStr,
    statusToStr,
    statusOptions,
    statusOptionIndex,
]

Session : {
    id : I64,
    user : [Guest, LoggedIn Str],
}

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

User : {
    id : I64,
    email : Str,
    name : Str,
}

NestedSet a : { value : a, left : I64, right : I64 }

Tree a : [
    Empty,
    Node a (List (Tree a)),
]

mapTree : Tree a, (a -> b) -> Tree b
mapTree = \tree, fn ->
    when tree is
        Empty -> Empty
        Node a children -> Node (fn a) (List.map children \child -> mapTree child fn)

nestedSetToTree : List (NestedSet a) -> Tree a where a implements Eq
nestedSetToTree = \nodes ->
    if List.isEmpty nodes then
        Empty
    else
        sortedNodes = List.sortWith nodes \first, second -> if first.left < second.left then LT else GT

        buildTree sortedNodes Empty
        |> mapTree .value

buildTree : List (NestedSet a), Tree (NestedSet a) -> Tree (NestedSet a) where a implements Eq
buildTree = \nodes, parentTree ->
    when (nodes, parentTree) is
        ([], Empty) -> Empty
        ([], Node _ _) -> parentTree
        ([current], Empty) -> Node current []
        ([current], Node parent _) ->
            isChild = current.left > parent.left && current.left < parent.right
            if isChild then
                buildTree [] (addChild parentTree current)
            else
                buildTree [] parentTree

        ([current, .. as rest], Empty) ->
            buildTree rest (Node current [])

        ([current, .. as rest], Node parent _) ->
            isChild = current.left > parent.left && current.left < parent.right
            if isChild then
                buildTree rest (addChild parentTree current)
            else
                buildTree rest parentTree

addChild : Tree (NestedSet a), NestedSet a -> Tree (NestedSet a) where a implements Eq
addChild = \tree, current ->
    when tree is
        Empty -> Empty
        Node parent children ->
            isChild = current.left > parent.left && current.left < parent.right
            if isChild then
                updatedChildren = List.map children \child -> addChild child current

                isChildOfChild = updatedChildren != children

                if isChildOfChild then
                    Node parent updatedChildren
                else
                    Node parent (List.append children (Node current []))
            else
                Node parent children

findNestedChildren : List (NestedSet a), NestedSet a -> List (NestedSet a)
findNestedChildren = \values, parent ->
    values |> List.keepIf \{ left } -> left > parent.left && left < parent.right

testValues = [
    { value: "Drinks", left: 1, right: 27 },
    { value: "Coffee", left: 2, right: 3 },
    { value: "Tea", left: 4, right: 20 },
    { value: "Black", left: 5, right: 8 },
    { value: "Green", left: 9, right: 19 },
    { value: "China", left: 10, right: 14 },
    { value: "Africa", left: 15, right: 18 },
    { value: "Milk", left: 21, right: 26 },
]

expect
    findNestedChildren testValues { value: "Green", left: 9, right: 19 }
    == [{ value: "China", left: 10, right: 14 }, { value: "Africa", left: 15, right: 18 }]

expect
    expected =
        Node "Drinks" [
            Node "Coffee" [],
            Node "Tea" [
                Node "Black" [],
                Node "Green" [
                    Node "China" [],
                    Node "Africa" [],
                ],
            ],
            Node "Milk" [],
        ]

    actual = nestedSetToTree testValues
    actual == expected

Date : [NotSet, Simple { year : I64, month : I64, day : I64 }, Invalid Str]

dateToStr : Date -> Str
dateToStr = \date ->

    # we need to ensure we add the leading zero for yyyy-mm-dd
    numToStr = \i64 ->
        if i64 < 10 then
            "0$(Num.toStr i64)"
        else
            Num.toStr i64

    when date is
        NotSet -> "Not Set"
        Simple { year, month, day } -> "$(numToStr year)-$(numToStr month)-$(numToStr day)"
        Invalid value -> "INVALID GOT '$(value)'"

# Not a serious implementation, just for demonstration purposes
parseDate : Str -> Result Date [InvalidDate Str]
parseDate = \date ->
    validYear = \y -> y > 1970 && y < 3000
    validMonth = \m -> m > 0 && m < 13
    validDay = \d -> d > 0 && d < 32

    isFourChars = \str -> List.len (Str.toUtf8 str) == 4
    isTwoChars = \str -> List.len (Str.toUtf8 str) == 2

    # Format: yyyy-mm-dd
    when Str.split date "-" is
        [""] -> Ok NotSet
        [yyyy, mm, dd] if isFourChars yyyy && isTwoChars mm && isTwoChars dd ->
            when (Str.toI64 yyyy, Str.toI64 mm, Str.toI64 dd) is
                (Ok year, Ok month, Ok day) if validYear year && validMonth month && validDay day -> Ok (Simple { year, month, day })
                _ -> Err (InvalidDate date)

        _ -> Err (InvalidDate date)

expect parseDate "2021-01-01" == Ok (Simple { year: 2021, month: 1, day: 1 })
expect parseDate "01-01-2024" == Err (InvalidDate "01-01-2024")
expect parseDate "" == Ok NotSet

Status : [Raised, Completed, Deferred, Approved, InProgress, Invalid Str]

statusToStr : Status -> Str
statusToStr = \s ->
    when s is
        Raised -> "Raised"
        Completed -> "Completed"
        Deferred -> "Deferred"
        Approved -> "Approved"
        InProgress -> "In-Progress"
        Invalid value -> "INVALID GOT '$(value)'"

statusOptions = ["Raised","Completed","Deferred","Approved","In-Progress"]
statusOptionIndex = \str ->
    when str is
        "Raised" -> Ok 0
        "Completed" -> Ok 1
        "Deferred" -> Ok 2
        "Approved" -> Ok 3
        "In-Progress" -> Ok 4
        _ -> Err (InvalidStatus str)

parseStatus : Str -> Result Status [InvalidStatus Str]
parseStatus = \status ->
    when status is
        "Raised" -> Ok Raised
        "Completed" -> Ok Completed
        "Deferred" -> Ok Deferred
        "Approved" -> Ok Approved
        "In-Progress" -> Ok InProgress
        _ -> Err (InvalidStatus status)

expect parseStatus "Raised" == Ok Raised
expect parseStatus "Completed" == Ok Completed
expect parseStatus "Deferred" == Ok Deferred
expect parseStatus "Approved" == Ok Approved
expect parseStatus "In-Progress" == Ok InProgress
expect parseStatus "definitely not valid" == Err (InvalidStatus "definitely not valid")

Priority : [Low, Medium, High, Invalid Str]

priorityToStr : Priority -> Str
priorityToStr = \p ->
    when p is
        Low -> "Low"
        Medium -> "Medium"
        High -> "High"
        Invalid value -> "INVALID GOT '$(value)'"

parsePriority : Str -> Priority
parsePriority = \priority ->
    when priority is
        "Low" -> Low
        "Medium" -> Medium
        "High" -> High
        _ -> Invalid priority

expect parsePriority "Low" == Low
expect parsePriority "Medium" == Medium
expect parsePriority "High" == High
expect parsePriority "" == Invalid ""

BigTask : {
    id : I64,
    referenceId : Str,
    customerReferenceId : Str,
    dateCreated : Date,
    dateModified : Date,
    title : Str,
    description : Str,
    status : Status,
    priority : Priority,
    scheduledStartDate : Date,
    scheduledEndDate : Date,
    actualStartDate : Date,
    actualEndDate : Date,
    systemName : Str,
    location : Str,
    fileReference : Str,
    comments : Str,
}
