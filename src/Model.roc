module [
    Session,
    Todo,
    User,
    Tree,
    NestedSet,
    emptyTodo,
    nestedSetToTree,
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
