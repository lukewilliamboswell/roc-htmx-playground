interface Pages.Home
    exposes [view]
    imports [
        html.Html,
        html.Attribute,
        Model.{Session},
        Layout.{layout},
        NavLinks,
    ]

view : {session : Session} -> Html.Node
view = \{session} ->
    layout {
        session, 
        description: "HOME PAGE", 
        title: "HOME", 
        navLinks : NavLinks.navLinks "Home", 
    } [
        Html.div [Attribute.class "container"] [
            Html.h1 [] [Html.text "Home"],
        ]
    ]