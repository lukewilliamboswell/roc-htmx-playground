TreeNode(a) := [Empty, Node(a, List(TreeNode(a)))].{}

Models :: [].{
	Auth := [Guest, LoggedIn(Str)]

	Session := {
		id : I64,
		user : Auth,
	}

	User := {
		id : I64,
		email : Str,
		name : Str,
	}.{
		parser_for : _
	}

	Todo := {
		id : I64,
		task : Str,
		status : Str,
	}.{
		parser_for : _
	}

	Tree(a) : TreeNode(a)

	BigTask := {
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
	}.{
		parser_for : _
	}

	SortDirection := [Ascending, Descending].{
		from_str : Str -> SortDirection
		from_str = |value|
			match value.with_ascii_lowercased() {
				"desc" => Descending
				_ => Ascending
			}

		to_str : SortDirection -> Str
		to_str = |direction|
			match direction {
				Ascending => "asc"
				Descending => "desc"
			}

		is_eq : _
	}

	SortColumn := [
		ById,
		ByReferenceId,
		ByCustomerReferenceId,
		ByDateCreated,
		ByDateModified,
		ByTitle,
		ByDescription,
		ByStatus,
		ByPriority,
		ByScheduledStartDate,
		ByScheduledEndDate,
		ByActualStartDate,
		ByActualEndDate,
		BySystemName,
		ByLocation,
		ByFileReference,
		ByComments,
	].{
		from_str : Str -> SortColumn
		from_str = |value|
			match value {
				"ReferenceID" => ByReferenceId
				"CustomerReferenceID" => ByCustomerReferenceId
				"DateCreated" => ByDateCreated
				"DateModified" => ByDateModified
				"Title" => ByTitle
				"Description" => ByDescription
				"Status" => ByStatus
				"Priority" => ByPriority
				"ScheduledStartDate" => ByScheduledStartDate
				"ScheduledEndDate" => ByScheduledEndDate
				"ActualStartDate" => ByActualStartDate
				"ActualEndDate" => ByActualEndDate
				"SystemName" => BySystemName
				"Location" => ByLocation
				"FileReference" => ByFileReference
				"Comments" => ByComments
				_ => ById
			}

		to_str : SortColumn -> Str
		to_str = |column|
			match column {
				ById => "ID"
				ByReferenceId => "ReferenceID"
				ByCustomerReferenceId => "CustomerReferenceID"
				ByDateCreated => "DateCreated"
				ByDateModified => "DateModified"
				ByTitle => "Title"
				ByDescription => "Description"
				ByStatus => "Status"
				ByPriority => "Priority"
				ByScheduledStartDate => "ScheduledStartDate"
				ByScheduledEndDate => "ScheduledEndDate"
				ByActualStartDate => "ActualStartDate"
				ByActualEndDate => "ActualEndDate"
				BySystemName => "SystemName"
				ByLocation => "Location"
				ByFileReference => "FileReference"
				ByComments => "Comments"
			}

		is_eq : _
	}

	BigTaskUpdate := [CustomerReferenceId(Str), DateCreated(Str), Status(Str)]

	NestedSetItem(a) := {
		value : a,
		left : I64,
		right : I64,
	}

	anonymousSession : Session
	anonymousSession = Session.{ id: 0, user: Guest }

	nestedSetToTree : List(NestedSetItem(a)) -> Tree(a)
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

buildTree : List(Models.NestedSetItem(a)), TreeNode(Models.NestedSetItem(a)) -> TreeNode(Models.NestedSetItem(a))
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

addChild : TreeNode(Models.NestedSetItem(a)), Models.NestedSetItem(a) -> TreeNode(Models.NestedSetItem(a))
addChild = |tree, current| {
	(updated, _) = addChildHelp(tree, current)
	updated
}

addChildHelp : TreeNode(Models.NestedSetItem(a)), Models.NestedSetItem(a) -> (TreeNode(Models.NestedSetItem(a)), Bool)
addChildHelp = |tree, current|
	match tree {
		Empty => (Empty, False)
		Node(parent, children) =>
			if isChild(current, parent) {
				state = children.fold(
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

isChild : Models.NestedSetItem(a), Models.NestedSetItem(b) -> Bool
isChild = |child, parent| child.left > parent.left and child.left < parent.right

## Sort direction parsing is case-insensitive.
expect Models.SortDirection.from_str("DESC") == Descending

## Known BigTask columns retain their canonical database name.
expect Models.SortColumn.from_str("Title").to_str() == "Title"

## Unknown BigTask columns safely fall back to the ID column.
expect Models.SortColumn.from_str("not-a-column") == ById
