Todo := {
	id : Id,
	task : Description,
	status : Status,
}.{
	Id :: I64.{
		from_i64 : I64 -> Id
		from_i64 = |value| Id.(value)

		from_str : Str -> Try(Id, [InvalidTodoId(Str)])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) => Ok(Id.(number))
				Err(_) => Err(InvalidTodoId(value))
			}

		to_i64 : Id -> I64
		to_i64 = |Id.(value)| value

		to_str : Id -> Str
		to_str = |id| id.to_i64().to_str()

		is_eq : _
	}

	Description :: Str.{
		from_str : Str -> Try(Description, [TaskWasEmpty])
		from_str = |value|
			if value.trim().is_empty() {
				Err(TaskWasEmpty)
			} else {
				Ok(Description.(value))
			}

		to_str : Description -> Str
		to_str = |Description.(value)| value

		is_eq : _
	}

	Status := [NotStarted, InProgress, Completed].{
		from_str : Str -> Try(Status, [InvalidTodoStatus(Str)])
		from_str = |value|
			match value {
				"Not Started" => Ok(NotStarted)
				"In-Progress" => Ok(InProgress)
				"Completed" => Ok(Completed)
				_ => Err(InvalidTodoStatus(value))
			}

		to_str : Status -> Str
		to_str = |status|
			match status {
				NotStarted => "Not Started"
				InProgress => "In-Progress"
				Completed => "Completed"
			}

		from_url_segment : Str -> Try(Status, [InvalidTodoStatusSegment(Str)])
		from_url_segment = |segment|
			match segment {
				"in-progress" => Ok(InProgress)
				"complete" => Ok(Completed)
				_ => Err(InvalidTodoStatusSegment(segment))
			}

		to_url_segment : Status -> Try(Str, [TodoStatusHasNoUpdateRoute])
		to_url_segment = |status|
			match status {
				InProgress => Ok("in-progress")
				Completed => Ok("complete")
				NotStarted => Err(TodoStatusHasNoUpdateRoute)
			}

		is_eq : _
	}

	New := {
		task : Description,
		status : Status,
	}.{
		is_eq : _
	}

	Tree(a) := [Empty, Node(a, List(Tree(a)))]

	NestedSetItem(a) := {
		value : a,
		left : I64,
		right : I64,
	}

	CreateError(err) := [InvalidDescription, StoreFailure(err)]

	complete_create : Try({}, err) -> Try({}, CreateError(err))
	complete_create = |stored|
		match stored {
			Ok({}) => Ok({})
			Err(error) => Err(CreateError.StoreFailure(error))
		}

	new : Str, Status -> Try(New, [TaskWasEmpty])
	new = |task, status| {
		description = Description.from_str(task)?
		Ok(New.{ task: description, status })
	}

	from_storage : I64, Str, Str -> Try(Todo, [InvalidTodoStatus(Str)])
	from_storage = |id, task, status| {
		parsed_status = Status.from_str(status)?
		Ok(
			Todo.{
				id: Id.from_i64(id),
				task: Description.(task),
				status: parsed_status,
			},
		)
	}

	nested_set_to_tree : List(NestedSetItem(a)) -> Tree(a)
	nested_set_to_tree = |nodes|
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
			map_tree(build_tree(sorted, Empty), |item| item.value)
		}

	## Validate a request value, then persist it through only the operation this
	## use case requires. Production and test stores participate through static
	## dispatch; there is no runtime interface value or repository superclass.
	create! : store, Str, Status => Try({}, CreateError(err))
		where [
			store.insert! : store, New => Try({}, err),
		]
	create! = |store, task, status| {
		Store : store
		match Todo.new(task, status) {
			Err(TaskWasEmpty) => Err(CreateError.InvalidDescription)
			Ok(new_todo) => {
				stored = Store.insert!(store, new_todo)
				Todo.complete_create(stored)
			}
		}
	}
}

map_tree : Todo.Tree(a), (a -> b) -> Todo.Tree(b)
map_tree = |tree, transform|
	match tree {
		Empty => Empty
		Node(value, children) => Node(transform(value), children.map(|child| map_tree(child, transform)))
	}

build_tree : List(Todo.NestedSetItem(a)), Todo.Tree(Todo.NestedSetItem(a)) -> Todo.Tree(Todo.NestedSetItem(a))
build_tree = |nodes, parent_tree|
	match (nodes, parent_tree) {
		([], Empty) => Empty
		([], Node(_, _)) => parent_tree
		([current], Empty) => Node(current, [])
		([current], Node(parent, _)) =>
			if is_child(current, parent) {
				build_tree([], add_child(parent_tree, current))
			} else {
				parent_tree
			}
		([current, .. as rest], Empty) => build_tree(rest, Node(current, []))
		([current, .. as rest], Node(parent, _)) =>
			if is_child(current, parent) {
				build_tree(rest, add_child(parent_tree, current))
			} else {
				build_tree(rest, parent_tree)
			}
		}

add_child : Todo.Tree(Todo.NestedSetItem(a)), Todo.NestedSetItem(a) -> Todo.Tree(Todo.NestedSetItem(a))
add_child = |tree, current| {
	(updated, _) = add_child_help(tree, current)
	updated
}

add_child_help : Todo.Tree(Todo.NestedSetItem(a)), Todo.NestedSetItem(a) -> (Todo.Tree(Todo.NestedSetItem(a)), Bool)
add_child_help = |tree, current|
	match tree {
		Empty => (Empty, False)
		Node(parent, children) =>
			if is_child(current, parent) {
				state = children.fold(
					{ children: [], inserted: False },
					|acc, child| {
						(updated_child, inserted) = add_child_help(child, current)
						{
							children: acc.children.append(updated_child),
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

is_child : Todo.NestedSetItem(a), Todo.NestedSetItem(b) -> Bool
is_child = |child, parent| child.left > parent.left and child.left < parent.right

expect Todo.Status.from_str("In-Progress") == Ok(InProgress)
expect Todo.new("  ", NotStarted) == Err(TaskWasEmpty)
expect Todo.complete_create(Ok({})).is_ok()
expect match Todo.complete_create(Err(DatabaseUnavailable)) {
	Err(Todo.CreateError.StoreFailure(DatabaseUnavailable)) => True
	_ => False
}
