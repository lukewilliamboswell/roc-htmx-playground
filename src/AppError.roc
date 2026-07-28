AppError := [Unauthorized, Forbidden, BadRequest(Str), NotFound(Str), Internal(Str)].{
	from : err -> AppError
	from = |error| Internal(Str.inspect(error))
}
