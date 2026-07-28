import http.Response

import Actor
import AppError
import Company
import CompanyStore
import CompanyView
import Http

CompanyHandler := [].{
	page! : CompanyStore, Actor, Company.Filter => Try(Response, AppError)
	page! = |store, actor, filter|
		match CompanyStore.list!(store, filter) {
			Ok(companies) =>
				Ok(
					Http.html(
						200,
						CompanyView.page({ actor, companies, filter }),
						[],
					),
				)
			Err(error) => Err(AppError.from(error))
		}

	detail! : CompanyStore, Actor, Company.Id => Try(Response, AppError)
	detail! = |store, actor, id|
		match CompanyStore.find!(store, id) {
			Ok(company) => Ok(Http.html(200, CompanyView.detail(actor, company), []))
			Err(Company.FindError.NotFound) =>
				Err(AppError.NotFound("company ${id.to_str()}"))
			Err(Company.FindError.StoreFailure(error)) => Err(AppError.from(error))
		}
}
