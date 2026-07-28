import pf.Attribute

Design :: [].{
	ButtonTone := [Primary, Secondary, Outline, Success, Danger, Warning]

	ButtonSize := [Regular, Small, Full]

	body : Attribute.Attribute
	body = class("min-h-screen bg-slate-50 font-sans text-slate-900 antialiased")

	page : Attribute.Attribute
	page = class("mx-auto w-full max-w-7xl px-4 py-8 sm:px-6 lg:px-8")

	pageTitle : Attribute.Attribute
	pageTitle = class("text-3xl font-bold tracking-tight text-slate-950")

	lead : Attribute.Attribute
	lead = class("mt-2 max-w-2xl text-lg leading-8 text-slate-600")

	actions : Attribute.Attribute
	actions = class("mt-6 flex flex-wrap gap-3")

	nav : Attribute.Attribute
	nav = class("border-b border-slate-200 bg-white shadow-sm")

	navInner : Attribute.Attribute
	navInner = class("mx-auto flex max-w-7xl flex-wrap items-center gap-4 px-4 py-3 sm:px-6 lg:px-8")

	brand : Attribute.Attribute
	brand = class("shrink-0 text-lg font-bold tracking-tight text-slate-950")

	navLinks : Attribute.Attribute
	navLinks = class("flex flex-1 flex-wrap items-center gap-1")

	navLink : Attribute.Attribute
	navLink = class("rounded-md px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600")

	auth : Attribute.Attribute
	auth = class("ml-auto flex items-center gap-2")

	userName : Attribute.Attribute
	userName = class("text-sm font-medium text-slate-700")

	button : ButtonTone, ButtonSize -> Attribute.Attribute
	button = |tone, size|
		class("${buttonBase} ${buttonToneClasses(tone)} ${buttonSizeClasses(size)}")

	downloadButton : Attribute.Attribute
	downloadButton = class("${buttonBase} ${buttonToneClasses(Success)} ${buttonSizeClasses(Regular)} mb-5 inline-flex")

	field : Attribute.Attribute
	field = class("mb-4 space-y-2")

	label : Attribute.Attribute
	label = class("block text-sm font-medium text-slate-700")

	input : Attribute.Attribute
	input = class("block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-4 focus:ring-blue-100")

	searchInput : Attribute.Attribute
	searchInput = class("mb-5 block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-4 focus:ring-blue-100")

	select : Attribute.Attribute
	select = class("block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100")

	validation : Attribute.Attribute
	validation = class("mt-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-700")

	tableFrame : Attribute.Attribute
	tableFrame = class("overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm")

	tableScroll : Attribute.Attribute
	tableScroll = class("overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-sm")

	table : Attribute.Attribute
	table = class("min-w-full divide-y divide-slate-200 text-left text-sm")

	tableHead : Attribute.Attribute
	tableHead = class("bg-slate-100")

	tableBody : Attribute.Attribute
	tableBody = class("divide-y divide-slate-100 bg-white")

	tableRow : Attribute.Attribute
	tableRow = class("transition hover:bg-slate-50")

	tableHeader : Attribute.Attribute
	tableHeader = class("px-4 py-3 text-xs font-semibold uppercase tracking-wide text-slate-600")

	sortableHeader : Attribute.Attribute
	sortableHeader = class("cursor-pointer px-4 py-3 text-xs font-semibold uppercase tracking-wide text-slate-600 transition hover:bg-slate-200 hover:text-slate-950")

	tableCell : Attribute.Attribute
	tableCell = class("whitespace-nowrap px-4 py-3 text-slate-700")

	tableCellWide : Attribute.Attribute
	tableCellWide = class("min-w-56 px-4 py-3 text-slate-700")

	tableActions : Attribute.Attribute
	tableActions = class("flex flex-wrap gap-2")

	todoForm : Attribute.Attribute
	todoForm = class("mt-6 grid gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-12")

	todoTask : Attribute.Attribute
	todoTask = class("md:col-span-8")

	todoStatus : Attribute.Attribute
	todoStatus = class("md:col-span-2")

	todoSubmit : Attribute.Attribute
	todoSubmit = class("md:col-span-2")

	tree : Attribute.Attribute
	tree = class("mt-5 space-y-2 rounded-xl border border-slate-200 bg-white p-5 shadow-sm")

	treeChildren : Attribute.Attribute
	treeChildren = class("ml-5 mt-2 space-y-2 border-l border-slate-200 pl-4")

	pagination : Attribute.Attribute
	pagination = class("mt-4 text-sm text-slate-600")
}

buttonBase = "inline-flex items-center justify-center rounded-lg font-semibold shadow-sm transition focus-visible:outline-2 focus-visible:outline-offset-2 disabled:pointer-events-none disabled:opacity-50"

buttonToneClasses : Design.ButtonTone -> Str
buttonToneClasses = |tone|
	match tone {
		Primary => "bg-blue-600 text-white hover:bg-blue-700 focus-visible:outline-blue-600"
		Secondary => "bg-slate-700 text-white hover:bg-slate-800 focus-visible:outline-slate-700"
		Outline => "border border-slate-300 bg-white text-slate-700 hover:bg-slate-100 hover:text-slate-950 focus-visible:outline-blue-600"
		Success => "bg-emerald-600 text-white hover:bg-emerald-700 focus-visible:outline-emerald-600"
		Danger => "border border-red-300 bg-white text-red-700 hover:bg-red-50 focus-visible:outline-red-600"
		Warning => "border border-amber-300 bg-white text-amber-800 hover:bg-amber-50 focus-visible:outline-amber-600"
	}

buttonSizeClasses : Design.ButtonSize -> Str
buttonSizeClasses = |size|
	match size {
		Regular => "gap-2 px-4 py-2 text-sm"
		Small => "gap-1.5 px-3 py-1.5 text-xs"
		Full => "w-full gap-2 px-4 py-2 text-sm"
	}

class : Str -> Attribute.Attribute
class = |value| Attribute.class(value)
