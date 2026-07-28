import pf.Attribute
import pf.Html

import Design

FormView := [].{
	text_field :
		Str, field, Str, Str -> Html.Node
			where [
				field.to_name : field -> Str,
			]
	text_field = |label, field, value, placeholder|
		text_field_with_requirement(label, field, value, placeholder, False)

	required_text_field :
		Str, field, Str, Str -> Html.Node
			where [
				field.to_name : field -> Str,
			]
	required_text_field = |label, field, value, placeholder|
		text_field_with_requirement(label, field, value, placeholder, True)

	select_field :
		Str, field, Str, List((Str, Str)) -> Html.Node
			where [
				field.to_name : field -> Str,
			]
	select_field = |label, field, selected, options|
		Html.div(
			[Design.field],
			[
				Html.label(
					[Attribute.for_(field.to_name()), Design.label],
					[Html.text(label)],
				),
				Html.select(
					[
						Attribute.id(field.to_name()),
						Attribute.name(field.to_name()),
						Design.select,
					],
					options.map(
						|(value, option_label)|
							Html.option(
								if value == selected {
									[Attribute.value(value), attribute("selected", "")]
								} else {
									[Attribute.value(value)]
								},
								[Html.text(option_label)],
							),
					),
				),
			],
		)
}

text_field_with_requirement :
	Str, field, Str, Str, Bool -> Html.Node
		where [
			field.to_name : field -> Str,
		]
text_field_with_requirement = |label, field, value, placeholder, required|
	Html.div(
		[Design.field],
		[
			Html.label(
				[Attribute.for_(field.to_name()), Design.label],
				[
					Html.text(label),
					if required {
						Html.span(
							[attribute("aria-hidden", "true"), Design.requiredHint],
							[Html.text(" (required)")],
						)
					} else {
						Html.text("")
					},
				],
			),
			Html.input(
				[
					Attribute.id(field.to_name()),
					Attribute.name(field.to_name()),
					Attribute.value(value),
					attribute("placeholder", placeholder),
					Design.input,
				].concat(
					if required {
						[attribute("required", "")]
					} else {
						[]
					},
				),
			),
		],
	)

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
