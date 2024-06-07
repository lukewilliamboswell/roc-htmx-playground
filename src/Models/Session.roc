module [
    Session,
    User,
    isAuthenticated,
]

Session page : {
    id : I64,
    user : [Guest, LoggedIn Str],
    page : Result page [NotSet],
} where page implements Decoding & Encoding

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
