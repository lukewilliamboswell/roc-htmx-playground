TreeNode(a) := [Empty, Node(a, List(TreeNode(a)))].{}

Models := [].{
	Session : {
		id : I64,
		user : [Guest, LoggedIn(Str)],
	}

	User : {
		id : I64,
		email : Str,
		name : Str,
	}

	Todo : {
		id : I64,
		task : Str,
		status : Str,
	}

	Tree(a) : TreeNode(a)

	BigTask : {
		id : I64,
		referenceId : Str,
		customerReferenceId : Str,
		dateCreated : Str,
		dateModified : Str,
		title : Str,
		description : Str,
		status : Str,
		priority : Str,
		scheduledStartDate : Str,
		scheduledEndDate : Str,
		actualStartDate : Str,
		actualEndDate : Str,
		systemName : Str,
		location : Str,
		fileReference : Str,
		comments : Str,
	}

	SortDirection : [Ascending, Descending]

	anonymousSession : Session
	anonymousSession = { id: 0, user: Guest }

	nestedSetToTree : List({ value : a, left : I64, right : I64 }) -> Tree(a)
	nestedSetToTree = |nodes|
		if nodes.is_empty() {
			Empty
		} else {
			sorted = nodes.sort_with(
				|first, second|
					if first.left < second.left {
						LT
					} else {
						GT
					},
			)
			mapTree(buildTree(sorted, Empty), |item| item.value)
		}
}

mapTree : TreeNode(a), (a -> b) -> TreeNode(b)
mapTree = |tree, transform|
	match tree {
		Empty => Empty
		Node(value, children) => Node(transform(value), children.map(|child| mapTree(child, transform)))
	}

buildTree : List({ value : a, left : I64, right : I64 }), TreeNode({ value : a, left : I64, right : I64 }) -> TreeNode({ value : a, left : I64, right : I64 })
buildTree = |nodes, parentTree|
	match (nodes, parentTree) {
		([], Empty) => Empty
		([], Node(_, _)) => parentTree
		([current], Empty) => Node(current, [])
		([current], Node(parent, _)) =>
			if isChild(current, parent) {
				buildTree([], addChild(parentTree, current))
			} else {
				parentTree
			}
		([current, .. as rest], Empty) => buildTree(rest, Node(current, []))
		([current, .. as rest], Node(parent, _)) =>
			if isChild(current, parent) {
				buildTree(rest, addChild(parentTree, current))
			} else {
				buildTree(rest, parentTree)
			}
		}

addChild : TreeNode({ value : a, left : I64, right : I64 }), { value : a, left : I64, right : I64 } -> TreeNode({ value : a, left : I64, right : I64 })
addChild = |tree, current| {
	(updated, _) = addChildHelp(tree, current)
	updated
}

addChildHelp = |tree, current|
	match tree {
		Empty => (Empty, False)
		Node(parent, children) =>
			if isChild(current, parent) {
				state = 
					children.fold(
						{ children: [], inserted: False },
						|acc, child| {
							(updatedChild, inserted) = addChildHelp(child, current)
							{
								children: acc.children.append(updatedChild),
								inserted: acc.inserted or inserted,
							}
						},
					)
				if state.inserted {
					(Node(parent, state.children), True)
				} else {
					(Node(parent, children.append(Node(current, []))), True)
				}
			} else {
				(Node(parent, children), False)
			}
		}

isChild = |child, parent| child.left > parent.left and child.left < parent.right
