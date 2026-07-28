import Member
import Session
import Workspace

Actor := {
	member : Member,
	session : Session,
	workspace : Workspace,
}.{
	from_session : Session, Workspace -> Try(Actor, [LoginRequired])
	from_session = |session, workspace|
		match session.user {
			Session.Auth.Guest => Err(LoginRequired)
			Session.Auth.LoggedIn(member) => Ok(Actor.{ member, session, workspace })
		}
}

expect Actor.from_session(
	Session.guest(Session.Id.from_i64(1)),
	Workspace.from_storage(
		"workspace-example",
		"Example",
		"AUD",
		"Australia/Melbourne",
		[],
		[],
	),
).is_err()
