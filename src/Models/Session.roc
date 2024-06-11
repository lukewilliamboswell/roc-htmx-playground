module [
    Session,
    User,
    isAuthenticated,
]

Session : {
    id : I64,
    user : [Guest, LoggedIn Str],
}

isAuthenticated : [Guest, LoggedIn Str] -> Result {} [Unauthorized]
isAuthenticated = \user ->
    if user == Guest then
        Err Unauthorized
    else
        Ok {}

User : {
    id : I64,
    email : Str,
    name : Str,
}
