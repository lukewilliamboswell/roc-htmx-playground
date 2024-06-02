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

Date : [NotSet, Simple {year : I64,month : I64,day : I64}, Invalid Str]

# Not a serious implementation, just for demonstration purposes
parseDate : Str -> Date
parseDate = \date ->
    validYear = \y -> y > 1970 && y < 3000
    validMonth = \m -> m > 0 && m < 13
    validDay = \d -> d > 0 && d < 32

    # Format: yyyy-mm-dd
    when Str.split date "-" is
        [""] -> NotSet
        [yyy, mm, dd] ->
            when (Str.toI64 yyy, Str.toI64 mm, Str.toI64 dd) is
                (Ok year, Ok month, Ok day) if validYear year && validMonth month && validDay day -> Simple { year, month, day }
                _ -> Invalid date
        _ -> Invalid date

expect parseDate "2021-01-01" == Simple { year: 2021, month: 1, day: 1 }
expect parseDate "01-01-2024" == Invalid "01-01-2024"
expect parseDate "" == NotSet

Status : [Raised, Completed, Deferred, Approved, InProgress, Invalid Str]

parseStatus : Str -> Status
parseStatus = \status ->
    when status is
        "Raised" -> Raised
        "Completed" -> Completed
        "Deferred" -> Deferred
        "Approved" -> Approved
        "In-Progress" -> InProgress
        _ -> Invalid status

expect parseStatus "Raised" == Raised
expect parseStatus "Completed" == Completed
expect parseStatus "Deferred" == Deferred
expect parseStatus "Approved" == Approved
expect parseStatus "In-Progress" == InProgress

Priority : [Low, Medium, High, Invalid Str]

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
