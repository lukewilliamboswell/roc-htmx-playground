import http.Response

import AppError
import Http
import Session
import UserStore
import UserView

UserHandler := [].{
	page! : UserStore, Session => Try(Response, AppError)
	page! = |store, session|
		match UserStore.list!(store) {
			Ok(users) => Ok(Http.html(200, UserView.page(session, users), []))
			Err(err) => Err(AppError.from(err))
		}
}
