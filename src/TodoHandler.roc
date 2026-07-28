import pf.Server
import http.Response

import AppError
import Http
import Route
import Session
import Todo
import TodoStore
import TodoView
import User
import Web

CreateForm := {
	task : Str,
	status : Todo.Status,
}

TodoHandler := [].{
	page! : store, Session => Try(Response, AppError)
		where [
			store.list! : store, Todo.Filter => Try(List(Todo), err),
		]
	page! = |store, session| {
		Store : store
		match Store.list!(store, Todo.Filter.empty) {
			Ok(todos) =>
				Ok(
					Http.html(
						200,
						TodoView.page({ session, todos, filter: Todo.Filter.empty }),
						[],
					),
				)
			Err(err) => Err(AppError.from(err))
		}
	}

	list! : store, Todo.Filter => Try(Response, AppError)
		where [
			store.list! : store, Todo.Filter => Try(List(Todo), err),
		]
	list! = |store, filter| {
		Store : store
		match Store.list!(store, filter) {
			Ok(todos) => Ok(Http.html(200, TodoView.list_fragment(todos), []))
			Err(err) => Err(AppError.from(err))
		}
	}

	search! : Server.Request, store => Try(Response, AppError)
		where [
			store.list! : store, Todo.Filter => Try(List(Todo), err),
		]
	search! = |request, store| {
		form = Http.read_form!(request)?
		TodoHandler.search_form!(form, store)
	}

	search_form! : Dict(Str, Str), store => Try(Response, AppError)
		where [
			store.list! : store, Todo.Filter => Try(List(Todo), err),
		]
	search_form! = |form, store| {
		filter = TodoHandler.search_filter(form)
		TodoHandler.list!(store, filter)
	}

	search_filter : Dict(Str, Str) -> Todo.Filter
	search_filter = |form|
		Todo.Filter.from_str(
			form.get(Route.TodoInput.to_name(Route.TodoInput.Filter)) ?? "",
		)

	create! : Server.Request, store => Try(Response, AppError)
		where [
			store.insert! : store, Todo.New => Try({}, err),
		]
	create! = |request, store| {
		form = Http.read_form!(request)?
		TodoHandler.create_form!(form, store)
	}

	create_form! : Dict(Str, Str), store => Try(Response, AppError)
		where [
			store.insert! : store, Todo.New => Try({}, err),
		]
	create_form! = |form, store| {
		input = TodoHandler.create_form(form)?
		result = Todo.create!(store, input.task, input.status)
		TodoHandler.create_response(result)
	}

	create_form : Dict(Str, Str) -> Try(CreateForm, AppError)
	create_form = |form| {
		task = form.get(Route.TodoInput.to_name(Route.TodoInput.Task)) ?? ""
		status_text = form.get(Route.TodoInput.to_name(Route.TodoInput.Status))
			?? Todo.Status.to_str(Todo.Status.NotStarted)
		status = Todo.Status.from_str(status_text)
			? |_| AppError.BadRequest("Expected a valid task status")
		Ok(CreateForm.{ task, status })
	}

	create_response : Try({}, Todo.CreateError(err)) -> Try(Response, AppError)
	create_response = |result|
		match result {
			Ok({}) => Ok(Web.redirect(Route.Page.Todos))
			Err(Todo.CreateError.InvalidDescription) =>
				Ok(Web.redirect(Route.Page.Todos))
			Err(Todo.CreateError.StoreFailure(err)) =>
				Err(AppError.from(err))
			}

	delete! : store, Todo.Id => Try(Response, AppError)
		where [
			store.delete! : store, Todo.Id => Try({}, delete_err),
			store.list! : store, Todo.Filter => Try(List(Todo), list_err),
		]
	delete! = |store, id| {
		Store : store
		match Store.delete!(store, id) {
			Err(err) => Err(AppError.from(err))
			Ok({}) => TodoHandler.list!(store, Todo.Filter.empty)
		}
	}

	update! : store, Todo.Id, Todo.Status => Try(Response, AppError)
		where [
			store.update_status! : store, Todo.Id, Todo.Status => Try({}, update_err),
			store.list! : store, Todo.Filter => Try(List(Todo), list_err),
		]
	update! = |store, id, status| {
		Store : store
		match Store.update_status!(store, id, status) {
			Err(err) => Err(AppError.from(err))
			Ok({}) => TodoHandler.list!(store, Todo.Filter.empty)
		}
	}

	tree_page! : store, Session => Try(Response, AppError)
		where [
			store.tree! : store, User.Id => Try(Todo.Tree(Todo), err),
		]
	tree_page! = |store, session| {
		Store : store
		match Store.tree!(store, User.Id.from_i64(1)) {
			Ok(tree) => Ok(Http.html(200, TodoView.tree_page(session, tree), []))
			Err(err) => Err(AppError.from(err))
		}
	}

	new_compatibility : () -> Response
	new_compatibility = || Web.redirect(Route.Page.Todos)
}

expect TodoHandler.search_filter(
	Dict.from_list([(Route.TodoInput.to_name(Route.TodoInput.Filter), "urgent")]),
) == Todo.Filter.from_str("urgent")
expect TodoHandler.search_filter(Dict.empty()) == Todo.Filter.empty

expect {
	result = TodoHandler.create_response(Ok({}))
	match result {
		Ok(response) =>
			Response.status(response) == 303
				and Response.headers(response).find_first(|header| header.name == "Location")
					== Ok({ name: "Location", value: "/task" })
		Err(_) => False
	}
}

expect match TodoHandler.create_response(Err(Todo.CreateError.StoreFailure(DatabaseUnavailable))) {
	Err(AppError.Internal(_)) => True
	_ => False
}
