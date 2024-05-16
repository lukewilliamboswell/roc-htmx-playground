module [view]

import html.Html
import html.Attribute
import Model exposing [Session]
import Layout exposing [layout]
import NavLinks

view : { session : Session } -> Html.Node
view = \{ session } ->
    layout
        {
            session,
            description: "HOME PAGE",
            title: "HOME",
            navLinks: NavLinks.navLinks "Home",
        }
        [
            Html.div [Attribute.class "container"] [
                Html.h1 [] [Html.text "Home"],
            ],
        ]
