import pf.Attribute

Design :: [].{
	ButtonTone := [Primary, Secondary, Outline, Success, Danger, Warning]

	ButtonSize := [Regular, Small, Full]

	BadgeTone := [Neutral, Active, Done]

	body : Attribute.Attribute
	body = class("min-h-screen bg-slate-50 font-sans text-slate-900 antialiased")

	page : Attribute.Attribute
	page = class("mx-auto w-full max-w-7xl px-4 py-8 sm:px-6 lg:px-8")

	pageTitle : Attribute.Attribute
	pageTitle = class("mb-6 text-3xl font-bold tracking-tight text-slate-950")

	backLinkedPageTitle : Attribute.Attribute
	backLinkedPageTitle = class("mt-4")

	pageHeader : Attribute.Attribute
	pageHeader = class("flex flex-wrap items-center justify-between gap-4")

	lead : Attribute.Attribute
	lead = class("-mt-4 max-w-2xl text-lg leading-8 text-slate-600")

	actions : Attribute.Attribute
	actions = class("mt-6 flex flex-wrap gap-3")

	hero : Attribute.Attribute
	hero = class("grid overflow-hidden rounded-2xl bg-slate-950 shadow-xl lg:grid-cols-2")

	crmHero : Attribute.Attribute
	crmHero = class("overflow-hidden rounded-2xl bg-slate-950 shadow-xl")

	crmHeroCopy : Attribute.Attribute
	crmHeroCopy = class("p-8 sm:p-12 lg:p-16")

	heroCopy : Attribute.Attribute
	heroCopy = class("flex flex-col justify-center p-8 sm:p-12 lg:p-16")

	eyebrow : Attribute.Attribute
	eyebrow = class("mb-3 text-sm font-semibold uppercase tracking-widest text-blue-300")

	heroTitle : Attribute.Attribute
	heroTitle = class("text-4xl font-bold tracking-tight text-white sm:text-5xl")

	heroLead : Attribute.Attribute
	heroLead = class("mt-5 max-w-xl text-lg leading-8 text-slate-300")

	heroActions : Attribute.Attribute
	heroActions = class("mt-8 flex flex-wrap gap-3")

	heroVisual : Attribute.Attribute
	heroVisual = class("relative h-80 min-h-72 lg:h-auto")

	heroImage : Attribute.Attribute
	heroImage = class("h-full w-full object-cover")

	photoCredit : Attribute.Attribute
	photoCredit = class("absolute bottom-3 right-3 rounded-md bg-slate-950/80 px-2 py-1 text-xs text-white")

	photoCreditLink : Attribute.Attribute
	photoCreditLink = class("underline underline-offset-2 hover:text-blue-200")

	featureHeading : Attribute.Attribute
	featureHeading = class("mt-12 text-2xl font-bold tracking-tight text-slate-950")

	featureLead : Attribute.Attribute
	featureLead = class("mt-2 max-w-2xl text-slate-600")

	featureGrid : Attribute.Attribute
	featureGrid = class("mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-4")

	featureCard : Attribute.Attribute
	featureCard = class("rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-1 hover:border-blue-200 hover:shadow-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600")

	featureIconFrame : Attribute.Attribute
	featureIconFrame = class("mb-4 inline-flex rounded-lg bg-blue-100 p-3")

	featureIcon : Attribute.Attribute
	featureIcon = class("h-6 w-6")

	featureTitle : Attribute.Attribute
	featureTitle = class("font-semibold text-slate-950")

	featureText : Attribute.Attribute
	featureText = class("mt-2 text-sm leading-6 text-slate-600")

	featureLink : Attribute.Attribute
	featureLink = class("mt-4 text-sm font-semibold text-blue-600")

	srOnly : Attribute.Attribute
	srOnly = class("sr-only")

	nav : Attribute.Attribute
	nav = class("border-b border-slate-200 bg-white shadow-sm")

	navInner : Attribute.Attribute
	navInner = class("mx-auto flex max-w-7xl flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3 sm:px-6 lg:px-8")

	brand : Attribute.Attribute
	brand = class("shrink-0 text-lg font-bold tracking-tight text-slate-950")

	navLinks : Attribute.Attribute
	navLinks = class("order-last flex w-full flex-wrap items-center gap-1 sm:order-none sm:w-auto sm:flex-1")

	navLink : Attribute.Attribute
	navLink = class("rounded-md px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600")

	auth : Attribute.Attribute
	auth = class("ml-auto flex shrink-0 items-center gap-2")

	userName : Attribute.Attribute
	userName = class("text-sm font-medium text-slate-700")

	button : ButtonTone, ButtonSize -> Attribute.Attribute
	button = |tone, size|
		class("${buttonBase} ${buttonToneClasses(tone)} ${buttonSizeClasses(size)}")

	downloadButton : Attribute.Attribute
	downloadButton = class("${buttonBase} ${buttonToneClasses(Success)} ${buttonSizeClasses(Regular)} mb-5 inline-flex")

	badge : BadgeTone -> Attribute.Attribute
	badge = |tone| class("${badgeBase} ${badgeToneClasses(tone)}")

	form : Attribute.Attribute
	form = class("max-w-md")

	recordForm : Attribute.Attribute
	recordForm = class("max-w-2xl rounded-xl border border-slate-200 bg-white p-6 shadow-sm")

	newRecordForm : Attribute.Attribute
	newRecordForm = class("mt-6 max-w-2xl rounded-xl border border-slate-200 bg-white p-6 shadow-sm")

	searchForm : Attribute.Attribute
	searchForm = class("mt-6")

	field : Attribute.Attribute
	field = class("mb-4 space-y-2")

	label : Attribute.Attribute
	label = class("block text-sm font-medium text-slate-700")

	input : Attribute.Attribute
	input = class("block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition placeholder:text-slate-500 focus:border-blue-500 focus:ring-4 focus:ring-blue-100")

	searchInput : Attribute.Attribute
	searchInput = class("mb-5 block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition placeholder:text-slate-500 focus:border-blue-500 focus:ring-4 focus:ring-blue-100")

	select : Attribute.Attribute
	select = class("block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100")

	validation : Attribute.Attribute
	validation = class("mt-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-700")

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
	sortableHeader = class("p-0")

	sortableHeaderButton : Attribute.Attribute
	sortableHeaderButton = class("flex w-full items-center gap-1.5 whitespace-nowrap px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-600 transition hover:bg-slate-200 hover:text-slate-950 focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-blue-600")

	sortIndicator : Attribute.Attribute
	sortIndicator = class("text-slate-400")

	sortIndicatorActive : Attribute.Attribute
	sortIndicatorActive = class("text-blue-600")

	tableCell : Attribute.Attribute
	tableCell = class("whitespace-nowrap px-4 py-3 text-slate-700")

	tableCellWide : Attribute.Attribute
	tableCellWide = class("min-w-56 px-4 py-3 text-slate-700")

	tableActions : Attribute.Attribute
	tableActions = class("flex flex-wrap gap-2")

	emptyState : Attribute.Attribute
	emptyState = class("px-4 py-10 text-center text-sm text-slate-500")

	detailGrid : Attribute.Attribute
	detailGrid = class("grid gap-6 lg:grid-cols-3")

	detailPrimaryCard : Attribute.Attribute
	detailPrimaryCard = class("rounded-xl border border-slate-200 bg-white p-5 shadow-sm lg:col-span-2")

	detailCard : Attribute.Attribute
	detailCard = class("rounded-xl border border-slate-200 bg-white p-5 shadow-sm")

	sectionHeading : Attribute.Attribute
	sectionHeading = class("text-lg font-semibold")

	contentSection : Attribute.Attribute
	contentSection = class("mt-6 rounded-xl border border-slate-200 bg-white p-5 shadow-sm")

	contentSectionText : Attribute.Attribute
	contentSectionText = class("mt-2 text-sm text-slate-600")

	recordLink : Attribute.Attribute
	recordLink = class("font-semibold text-blue-700 hover:underline")

	secondaryText : Attribute.Attribute
	secondaryText = class("text-sm text-slate-600")

	detailList : Attribute.Attribute
	detailList = class("mt-4 grid gap-4 sm:grid-cols-2")

	detailTerm : Attribute.Attribute
	detailTerm = class("text-sm font-medium text-slate-500")

	detailValue : Attribute.Attribute
	detailValue = class("mt-1 text-sm text-slate-900")

	warningPanel : Attribute.Attribute
	warningPanel = class("mb-6 rounded-xl border border-amber-300 bg-amber-50 p-5")

	warningPanelSpaced : Attribute.Attribute
	warningPanelSpaced = class("mt-6 rounded-xl border border-amber-300 bg-amber-50 p-5")

	warningHeading : Attribute.Attribute
	warningHeading = class("font-semibold text-amber-950")

	warningSectionHeading : Attribute.Attribute
	warningSectionHeading = class("text-lg font-semibold text-amber-950")

	warningText : Attribute.Attribute
	warningText = class("mt-1 text-sm text-amber-900")

	matchList : Attribute.Attribute
	matchList = class("mt-4 space-y-3")

	matchItem : Attribute.Attribute
	matchItem = class("rounded-lg bg-white p-3")

	contactList : Attribute.Attribute
	contactList = class("mt-4 space-y-3")

	contactRow : Attribute.Attribute
	contactRow = class("flex flex-wrap items-center justify-between gap-3 rounded-lg border border-slate-200 p-3")

	contactMeta : Attribute.Attribute
	contactMeta = class("text-xs font-medium uppercase tracking-wide text-slate-500")

	inlineForm : Attribute.Attribute
	inlineForm = class("mt-4 grid gap-3 rounded-lg bg-slate-50 p-4 sm:grid-cols-2")

	checkboxLabel : Attribute.Attribute
	checkboxLabel = class("flex items-center gap-2 text-sm text-slate-700")

	fullWidthField : Attribute.Attribute
	fullWidthField = class("sm:col-span-2")

	dangerLinkButton : Attribute.Attribute
	dangerLinkButton = class("text-sm font-medium text-red-700 hover:underline")

	workGrid : Attribute.Attribute
	workGrid = class("mt-6 grid gap-6 lg:grid-cols-3")

	workBucket : Attribute.Attribute
	workBucket = class("rounded-xl border border-slate-200 bg-white p-5 shadow-sm")

	overdueBucket : Attribute.Attribute
	overdueBucket = class("rounded-xl border border-red-200 bg-red-50 p-5 shadow-sm")

	taskList : Attribute.Attribute
	taskList = class("mt-4 space-y-3")

	taskItem : Attribute.Attribute
	taskItem = class("rounded-lg border border-slate-200 bg-white p-4")

	taskSubject : Attribute.Attribute
	taskSubject = class("font-semibold text-slate-950")

	taskDue : Attribute.Attribute
	taskDue = class("mt-1 text-sm font-medium text-slate-700")

	taskRelated : Attribute.Attribute
	taskRelated = class("mt-1 text-sm text-slate-500")

	taskActions : Attribute.Attribute
	taskActions = class("mt-3")

	todoForm : Attribute.Attribute
	todoForm = class("mt-6 grid gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-12")

	todoTask : Attribute.Attribute
	todoTask = class("md:col-span-8")

	todoStatus : Attribute.Attribute
	todoStatus = class("md:col-span-2")

	todoSubmit : Attribute.Attribute
	todoSubmit = class("md:col-span-2")

	tree : Attribute.Attribute
	tree = class("space-y-2 rounded-xl border border-slate-200 bg-white p-5 shadow-sm")

	treeChildren : Attribute.Attribute
	treeChildren = class("ml-5 mt-2 space-y-2 border-l border-slate-200 pl-4")

	pagination : Attribute.Attribute
	pagination = class("mt-4 flex flex-wrap items-center justify-between gap-3")

	paginationInfo : Attribute.Attribute
	paginationInfo = class("text-sm text-slate-600")

	paginationLinks : Attribute.Attribute
	paginationLinks = class("flex flex-wrap items-center gap-2")

	paginationLink : Attribute.Attribute
	paginationLink = class("${buttonBase} ${buttonToneClasses(Outline)} ${buttonSizeClasses(Small)}")

	paginationDisabled : Attribute.Attribute
	paginationDisabled = class("${buttonBase} ${buttonSizeClasses(Small)} cursor-not-allowed border border-slate-200 bg-slate-50 text-slate-400")
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

badgeBase = "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"

badgeToneClasses : Design.BadgeTone -> Str
badgeToneClasses = |tone|
	match tone {
		Neutral => "bg-slate-100 text-slate-700"
		Active => "bg-amber-100 text-amber-800"
		Done => "bg-emerald-100 text-emerald-800"
	}

class : Str -> Attribute.Attribute
class = |value| Attribute.class(value)
