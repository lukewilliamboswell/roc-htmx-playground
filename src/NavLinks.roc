module [NavLink, navLinks]

NavLink : [
    Active { label : Str, href : Str },
    Inactive { label : Str, href : Str },
]

navLinks : Str -> List NavLink
navLinks = \active ->
    [
        Inactive { label: "Home", href: "/" },
        Inactive { label: "Tasks", href: "/task" },
        Inactive { label: "Users", href: "/user" },
        Inactive { label: "TreeView", href: "/treeview" },
        Inactive { label: "BigTask", href: "/bigTask" },
    ]
    |> List.map \navLink ->
        when navLink is
            Inactive config if config.label == active -> Active config
            _ -> navLink
