import pf.Sqlite

import Workspace

WorkspaceStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> WorkspaceStore
	new = |db| WorkspaceStore.{ db }

	load! : WorkspaceStore => Try(Workspace, Workspace.LoadError(Sqlite.QueryError))
	load! = |store| {
		workspace_rows : List({ currency : Str, id : Str, name : Str, timezone : Str })
		workspace_rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT workspace_id AS id, name, currency, timezone
				\\FROM workspaces
				\\ORDER BY workspace_id;
				,
			),
			params: {},
			limits: Sqlite.default_query_limits,
		}) ? Workspace.LoadError.StoreFailure

		match workspace_rows {
			[] => Err(Workspace.LoadError.MissingWorkspace)
			[_, _, ..] => Err(Workspace.LoadError.MultipleWorkspaces)
			[row] => {
				source_rows : List({ active : I64, id : Str, name : Str, position : I64 })
				source_rows = Sqlite.query_many!({
					db: store.db,
					query: (
						\\SELECT source_id AS id, name, position, active
						\\FROM sources
						\\WHERE workspace_id = :workspaceId
						\\ORDER BY position, source_id;
						,
					),
					params: { workspaceId: row.id },
					limits: Sqlite.default_query_limits,
				}) ? Workspace.LoadError.StoreFailure

				task_type_rows : List({ active : I64, id : Str, name : Str, position : I64 })
				task_type_rows = Sqlite.query_many!({
					db: store.db,
					query: (
						\\SELECT task_type_id AS id, name, position, active
						\\FROM task_types
						\\WHERE workspace_id = :workspaceId
						\\ORDER BY position, task_type_id;
						,
					),
					params: { workspaceId: row.id },
					limits: Sqlite.default_query_limits,
				}) ? Workspace.LoadError.StoreFailure

				Ok(
					Workspace.from_storage(
						row.id,
						row.name,
						row.currency,
						row.timezone,
						source_rows.map(
							|source|
								Workspace.source_from_storage(
									source.id,
									source.name,
									source.position,
									source.active,
								),
						),
						task_type_rows.map(
							|task_type|
								Workspace.task_type_from_storage(
									task_type.id,
									task_type.name,
									task_type.position,
									task_type.active,
								),
						),
					),
				)
			}
		}
	}
}
