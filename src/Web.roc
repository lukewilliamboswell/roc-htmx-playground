import pf.Attribute
import pf.Html
import http.Response

import Route

## Shared HTTP and HTML helpers.
##
## These helpers intentionally ask for different URL-producing methods. A
## navigable location cannot accidentally be used as a mutation endpoint, and
## a PUT action cannot accidentally be rendered as a POST action. Roc resolves
## the `where` constraints with static dispatch, so this abstraction does not
## require a function record or runtime dispatch.
Web := [].{
	Header : { name : Str, value : Str }

	ErrorTarget := [RequestError].{
		to_selector : ErrorTarget -> Str
		to_selector = |_| "#request-error"

		to_id : ErrorTarget -> Str
		to_id = |_| "request-error"
	}

	Swap := [InnerHtml, OuterHtml].{
		to_attribute : Swap -> Str
		to_attribute = |swap|
			match swap {
				InnerHtml => "innerHTML"
				OuterHtml => "outerHTML"
			}
	}

	href : location -> Attribute.Attribute
		where [
			location.to_href : location -> Str,
		]
	href = |location| Attribute.href(location.to_href())

	link : location, List(Attribute.Attribute), List(Html.Node) -> Html.Node
		where [
			location.to_href : location -> Str,
		]
	link = |location, attributes, children|
		Html.a([Attribute.href(location.to_href())].concat(attributes), children)

	asset_src : asset -> Attribute.Attribute
		where [
			asset.to_src : asset -> Str,
		]
	asset_src = |asset| Attribute.src(asset.to_src())

	asset_href : asset -> Attribute.Attribute
		where [
			asset.to_src : asset -> Str,
		]
	asset_href = |asset| Attribute.href(asset.to_src())

	post_action : action -> Attribute.Attribute
		where [
			action.to_post_url : action -> Str,
		]
	post_action = |action| Attribute.action(action.to_post_url())

	post_form : action, List(Attribute.Attribute), List(Html.Node) -> Html.Node
		where [
			action.to_post_url : action -> Str,
		]
	post_form = |action, attributes, children|
		Html.form(
			[
				Attribute.action(action.to_post_url()),
				Attribute.method("post"),
			].concat(attributes),
			children,
		)

	get_form : location, List(Attribute.Attribute), List(Html.Node) -> Html.Node
		where [
			location.to_href : location -> Str,
		]
	get_form = |location, attributes, children|
		Html.form(
			[
				Attribute.action(location.to_href()),
				Attribute.method("get"),
			].concat(attributes),
			children,
		)

	hx_get : location -> Attribute.Attribute
		where [
			location.to_href : location -> Str,
		]
	hx_get = |location| Attribute.attribute("hx-get", location.to_href())

	hx_post : action -> Attribute.Attribute
		where [
			action.to_post_url : action -> Str,
		]
	hx_post = |action| Attribute.attribute("hx-post", action.to_post_url())

	hx_put : action -> Attribute.Attribute
		where [
			action.to_put_url : action -> Str,
		]
	hx_put = |action| Attribute.attribute("hx-put", action.to_put_url())

	hx_target : target -> Attribute.Attribute
		where [
			target.to_selector : target -> Str,
		]
	hx_target = |target| Attribute.attribute("hx-target", target.to_selector())

	hx_select : target -> Attribute.Attribute
		where [
			target.to_selector : target -> Str,
		]
	hx_select = |target| Attribute.attribute("hx-select", target.to_selector())

	hx_swap : Swap -> Attribute.Attribute
	hx_swap = |swap| Attribute.attribute("hx-swap", swap.to_attribute())

	## Mark the stable region restored when browser history is traversed.
	hx_history_element : Attribute.Attribute
	hx_history_element = Attribute.attribute("hx-history-elt", "")

	## Keep the address bar aligned with rapidly changing meaningful state
	## without adding one browser-history entry per change.
	hx_replace_url : Attribute.Attribute
	hx_replace_url = Attribute.attribute("hx-replace-url", "true")

	## Keep only the newest request issued by the element.
	##
	## This is appropriate for derived UI such as live search, where an older
	## response must never replace newer state. Persisted writes additionally
	## require an optimistic version or another server-side ordering invariant.
	hx_sync_latest : Attribute.Attribute
	hx_sync_latest = Attribute.attribute("hx-sync", "this:replace")

	## Keep the first mutation request and ignore repeated submissions until it
	## finishes. Persistence must still enforce the transition exactly once.
	hx_sync_first : Attribute.Attribute
	hx_sync_first = Attribute.attribute("hx-sync", "this:drop")

	## Route expected and unexpected HTTP failures into a local feedback region
	## without replacing the interaction's normal success target.
	hx_errors_to : target -> List(Attribute.Attribute)
		where [
			target.to_selector : target -> Str,
		]
	hx_errors_to = |target| {
		policy = "target:${target.to_selector()} select:${ErrorTarget.to_selector(ErrorTarget.RequestError)} swap:innerHTML"
		[
			Attribute.attribute("hx-status:4xx", policy),
			Attribute.attribute("hx-status:5xx", policy),
		]
	}

	## Opt one interaction into persistent local feedback for failures that
	## have no HTTP response, such as a lost connection or timeout.
	network_errors_to : target -> Attribute.Attribute
		where [
			target.to_id : target -> Str,
		]
	network_errors_to = |target|
		Attribute.attribute("data-network-error-target", target.to_id())

	## Restore keyboard orientation after a successful swap removes the control
	## that initiated it.
	focus_after_swap : target -> Attribute.Attribute
		where [
			target.to_id : target -> Str,
		]
	focus_after_swap = |target|
		Attribute.attribute("data-focus-after-swap", target.to_id())

	redirect : location -> Response
		where [
			location.to_href : location -> Str,
		]
	redirect = |location| redirect_with_headers(location, [])

	redirect_with_headers : location, List(Header) -> Response
		where [
			location.to_href : location -> Str,
		]
	redirect_with_headers = |location, headers|
		Response.from_status(303)
			.with_headers(
				[{ name: "Location", value: location.to_href() }].concat(headers),
			)

	hx_push_header : location -> Header
		where [
			location.to_href : location -> Str,
		]
	hx_push_header = |location| {
		name: "HX-Push-Url",
		value: location.to_href(),
	}
}

expect {
	response = Web.redirect(Route.Page.Todos)
	headers = Response.headers(response)
	Response.status(response) == 303
		and headers.find_first(|header| header.name == "Location")
			== Ok({ name: "Location", value: "/task" })
}
