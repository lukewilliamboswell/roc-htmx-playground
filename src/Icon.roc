import pf.Attribute
import pf.Html

## Inline interface icons.
##
## Icons are rendered into the document rather than fetched so navigation
## chrome paints with the first response and never flashes an empty tab bar.
## Each icon receives its sizing attribute from `Design`, which keeps every
## Tailwind class string in that one module.
Icon := [].{

	## A building: the Companies section.
	building : Attribute.Attribute -> Html.Node
	building = |size|
		stroked(
			size,
			[
				"M3 21h18",
				"M5 21V5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v16",
				"M15 11h2a2 2 0 0 1 2 2v8",
				"M9 7h2",
				"M9 11h2",
				"M9 15h2",
			],
		)

	## Two figures: the People section.
	users : Attribute.Attribute -> Html.Node
	users = |size|
		stroked(
			size,
			[
				"M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2",
				"M5 7a4 4 0 1 0 8 0a4 4 0 1 0-8 0",
				"M22 21v-2a4 4 0 0 0-3-3.87",
				"M16 3.13a4 4 0 0 1 0 7.75",
			],
		)

	## A completed check: the My Work section.
	checkCircle : Attribute.Attribute -> Html.Node
	checkCircle = |size|
		stroked(
			size,
			[
				"M22 11.08V12a10 10 0 1 1-5.93-9.14",
				"m22 4-10 10.01-3-3",
			],
		)

	## A checklist: the application brand mark.
	listChecks : Attribute.Attribute -> Html.Node
	listChecks = |size|
		stroked(
			size,
			[
				"m3 17 2 2 4-4",
				"m3 7 2 2 4-4",
				"M13 6h8",
				"M13 12h8",
				"M13 18h8",
			],
		)

	## Forward affordance on a tappable record card.
	chevronRight : Attribute.Attribute -> Html.Node
	chevronRight = |size| stroked(size, ["m9 18 6-6-6-6"])

	## Return affordance on a detail or form page.
	arrowLeft : Attribute.Attribute -> Html.Node
	arrowLeft = |size| stroked(size, ["M19 12H5", "m12 19-7-7 7-7"])

	## An empty tray: a record list with nothing in it yet.
	inbox : Attribute.Attribute -> Html.Node
	inbox = |size|
		stroked(
			size,
			[
				"M22 12h-6l-2 3h-4l-2-3H2",
				"M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z",
			],
		)

	## A magnifier: a search that matched nothing.
	searchOff : Attribute.Attribute -> Html.Node
	searchOff = |size|
		stroked(
			size,
			[
				"M3 11a8 8 0 1 0 16 0a8 8 0 1 0-16 0",
				"m21 21-4.35-4.35",
			],
		)
}

## Every icon shares one 24-unit grid and inherits colour from its container,
## so an icon can be recoloured by styling the element that holds it.
stroked : Attribute.Attribute, List(Str) -> Html.Node
stroked = |size, paths|
	Html.svg(
		[
			size,
			attribute("viewBox", "0 0 24 24"),
			attribute("fill", "none"),
			attribute("stroke", "currentColor"),
			attribute("stroke-width", "1.75"),
			attribute("stroke-linecap", "round"),
			attribute("stroke-linejoin", "round"),
			attribute("aria-hidden", "true"),
		],
		paths.map(|d| Html.element("path", [attribute("d", d)], [])),
	)

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
