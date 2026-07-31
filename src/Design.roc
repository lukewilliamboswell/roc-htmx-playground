import pf.Attribute

Design :: [].{
	ButtonTone := [Primary, Secondary, Outline, Success, Danger, Warning]

	ButtonSize := [Regular, Small, Full]

	BadgeTone := [Neutral, Active, Done]

	## Reserve room for the fixed mobile tab bar, including the iOS home
	## indicator, so the last row of any list stays reachable.
	body : Attribute.Attribute
	body = class("min-h-screen bg-slate-50 pb-[calc(4.5rem+env(safe-area-inset-bottom))] font-sans text-slate-900 antialiased sm:pb-0")

	page : Attribute.Attribute
	page = class("mx-auto w-full max-w-7xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8")

	pageTitle : Attribute.Attribute
	pageTitle = class("text-2xl font-bold tracking-tight text-balance text-slate-950 sm:text-3xl")

	backLinkedPageTitle : Attribute.Attribute
	backLinkedPageTitle = class("mt-3")

	pageHeader : Attribute.Attribute
	pageHeader = class("mb-5 flex flex-wrap items-end justify-between gap-x-4 gap-y-3")

	lead : Attribute.Attribute
	lead = class("mt-2 max-w-2xl text-pretty text-slate-600 sm:text-lg sm:leading-8")

	actions : Attribute.Attribute
	actions = class("mt-6 flex flex-wrap gap-3")

	hero : Attribute.Attribute
	hero = class("grid overflow-hidden rounded-2xl bg-slate-950 shadow-xl lg:grid-cols-2")

	heroCopy : Attribute.Attribute
	heroCopy = class("flex flex-col justify-center p-6 sm:p-10 lg:p-14")

	eyebrow : Attribute.Attribute
	eyebrow = class("mb-3 text-xs font-semibold uppercase tracking-widest text-blue-300 sm:text-sm")

	heroTitle : Attribute.Attribute
	heroTitle = class("text-3xl font-bold tracking-tight text-balance text-white sm:text-4xl lg:text-5xl")

	heroLead : Attribute.Attribute
	heroLead = class("mt-4 max-w-xl text-pretty leading-7 text-slate-300 sm:mt-5 sm:text-lg sm:leading-8")

	## A grid on small screens so both calls to action span the full width and
	## present equal-sized touch targets; a normal inline row from `sm` up.
	heroActions : Attribute.Attribute
	heroActions = class("mt-6 grid gap-3 sm:mt-8 sm:flex sm:flex-wrap")

	## The photograph leads on small screens and moves beside the copy on large
	## ones, so the headline still occupies the first mobile viewport.
	heroVisual : Attribute.Attribute
	heroVisual = class("relative order-first h-36 w-full sm:h-60 lg:order-last lg:h-auto")

	heroImage : Attribute.Attribute
	heroImage = class("h-full w-full object-cover")

	photoCredit : Attribute.Attribute
	photoCredit = class("absolute bottom-2 right-2 rounded-md bg-slate-950/75 px-2 py-1 text-[0.6875rem] text-slate-200")

	photoCreditLink : Attribute.Attribute
	photoCreditLink = class("underline underline-offset-2 hover:text-white")

	featureHeading : Attribute.Attribute
	featureHeading = class("mt-10 text-xl font-bold tracking-tight text-slate-950 sm:mt-12 sm:text-2xl")

	featureLead : Attribute.Attribute
	featureLead = class("mt-2 max-w-2xl text-pretty text-slate-600")

	featureGrid : Attribute.Attribute
	featureGrid = class("mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3")

	featureCard : Attribute.Attribute
	featureCard = class("flex flex-col rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:border-blue-200 hover:shadow-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 sm:hover:-translate-y-1")

	featureIconFrame : Attribute.Attribute
	featureIconFrame = class("mb-4 inline-flex w-fit rounded-lg bg-blue-50 p-2.5 text-blue-600 ring-1 ring-inset ring-blue-100")

	featureIcon : Attribute.Attribute
	featureIcon = class("h-5 w-5")

	featureTitle : Attribute.Attribute
	featureTitle = class("font-semibold text-slate-950")

	featureText : Attribute.Attribute
	featureText = class("mt-2 grow text-sm leading-6 text-slate-600")

	featureLink : Attribute.Attribute
	featureLink = class("mt-4 text-sm font-semibold text-blue-600")

	srOnly : Attribute.Attribute
	srOnly = class("sr-only")

	nav : Attribute.Attribute
	nav = class("sticky top-0 z-40 border-b border-slate-200 bg-white/90 backdrop-blur")

	navInner : Attribute.Attribute
	navInner = class("mx-auto flex max-w-7xl items-center gap-3 px-4 py-2.5 sm:gap-4 sm:px-6 sm:py-3 lg:px-8")

	brand : Attribute.Attribute
	brand = class("flex shrink-0 items-center gap-2 text-base font-bold tracking-tight text-slate-950 sm:text-lg")

	brandMark : Attribute.Attribute
	brandMark = class("inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-blue-600 text-white shadow-sm")

	brandMarkIcon : Attribute.Attribute
	brandMarkIcon = class("h-4 w-4")

	## Hidden on small screens because `tabBar` owns mobile navigation.
	navLinks : Attribute.Attribute
	navLinks = class("hidden items-center gap-1 sm:flex")

	navLink : Attribute.Attribute
	navLink = class("rounded-md px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600")

	navLinkActive : Attribute.Attribute
	navLinkActive = class("rounded-md bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600")

	auth : Attribute.Attribute
	auth = class("ml-auto flex min-w-0 shrink items-center gap-2")

	userName : Attribute.Attribute
	userName = class("truncate text-sm font-medium text-slate-700")

	devBadge : Attribute.Attribute
	devBadge = class("inline-flex shrink-0 items-center rounded-full bg-amber-100 px-2 py-0.5 text-[0.6875rem] font-semibold uppercase tracking-wide text-amber-800")

	## Fixed thumb-reachable navigation, small screens only.
	tabBar : Attribute.Attribute
	tabBar = class("fixed inset-x-0 bottom-0 z-40 border-t border-slate-200 bg-white/95 pb-[env(safe-area-inset-bottom)] backdrop-blur sm:hidden")

	tabBarInner : Attribute.Attribute
	tabBarInner = class("mx-auto grid max-w-lg grid-cols-3")

	tabLink : Attribute.Attribute
	tabLink = class("flex flex-col items-center justify-center gap-1 px-2 py-2.5 text-xs font-medium text-slate-500 transition active:bg-slate-100")

	tabLinkActive : Attribute.Attribute
	tabLinkActive = class("flex flex-col items-center justify-center gap-1 px-2 py-2.5 text-xs font-semibold text-blue-600 transition active:bg-slate-100")

	tabIcon : Attribute.Attribute
	tabIcon = class("h-6 w-6")

	backLink : Attribute.Attribute
	backLink = class("-ml-1 inline-flex items-center gap-1 rounded-md px-1 py-1 text-sm font-medium text-slate-600 transition hover:text-slate-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600")

	backLinkIcon : Attribute.Attribute
	backLinkIcon = class("h-4 w-4")

	## Record-level actions sitting between a page heading and its content.
	pageActions : Attribute.Attribute
	pageActions = class("mt-4 mb-6 flex flex-wrap gap-3")

	button : ButtonTone, ButtonSize -> Attribute.Attribute
	button = |tone, size|
		class("${buttonBase} ${buttonToneClasses(tone)} ${buttonSizeClasses(size)}")

	badge : BadgeTone -> Attribute.Attribute
	badge = |tone| class("${badgeBase} ${badgeToneClasses(tone)}")

	form : Attribute.Attribute
	form = class("max-w-md")

	recordForm : Attribute.Attribute
	recordForm = class("max-w-2xl rounded-xl border border-slate-200 bg-white p-6 shadow-sm")

	newRecordForm : Attribute.Attribute
	newRecordForm = class("mt-6 max-w-2xl rounded-xl border border-slate-200 bg-white p-6 shadow-sm")

	searchForm : Attribute.Attribute
	searchForm = class("mt-5")

	## One row at every width. A stacked full-width submit button reads as a
	## primary page action rather than as part of the search field.
	searchControls : Attribute.Attribute
	searchControls = class("mb-5 mt-2 flex gap-2")

	field : Attribute.Attribute
	field = class("mb-4 space-y-2")

	label : Attribute.Attribute
	label = class("block text-sm font-medium text-slate-700")

	requiredHint : Attribute.Attribute
	requiredHint = class("font-normal text-slate-500")

	fieldHelp : Attribute.Attribute
	fieldHelp = class("text-sm leading-6 text-slate-600")

	helpDisclosure : Attribute.Attribute
	helpDisclosure = class("text-sm text-slate-600")

	helpSummary : Attribute.Attribute
	helpSummary = class("w-fit cursor-pointer font-medium text-blue-700 hover:underline focus-visible:rounded-sm focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600")

	helpList : Attribute.Attribute
	helpList = class("mt-3 space-y-2 border-l-2 border-slate-200 pl-4")

	helpTerm : Attribute.Attribute
	helpTerm = class("font-medium text-slate-800")

	input : Attribute.Attribute
	input = class("block min-h-11 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition placeholder:text-slate-500 focus:border-blue-500 focus:ring-4 focus:ring-blue-100 pointer-fine:min-h-0")

	searchInput : Attribute.Attribute
	searchInput = class("block min-h-11 min-w-0 flex-1 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition placeholder:text-slate-500 focus:border-blue-500 focus:ring-4 focus:ring-blue-100 pointer-fine:min-h-0")

	select : Attribute.Attribute
	select = class("block min-h-11 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100 pointer-fine:min-h-0")

	contactInputRow : Attribute.Attribute
	contactInputRow = class("grid gap-2 sm:grid-cols-[9rem_1fr]")

	contactTypeSelect : Attribute.Attribute
	contactTypeSelect = class("block min-h-11 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100 pointer-fine:min-h-0")

	validation : Attribute.Attribute
	validation = class("mt-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-700")

	## One table serves every width, rather than a card list and a table both
	## rendered into the same document. Below `sm` the table elements are laid
	## out as blocks, so each row reads as a card of labelled lines; from `sm`
	## up they are table elements again, so a wide screen keeps column scanning
	## and header association. Rendering the list once keeps the document small
	## and leaves exactly one link per record in the accessibility tree.
	tableScroll : Attribute.Attribute
	tableScroll = class("sm:overflow-x-auto sm:rounded-xl sm:border sm:border-slate-200 sm:bg-white sm:shadow-sm")

	table : Attribute.Attribute
	table = class("block w-full text-left text-sm sm:table sm:min-w-full")

	tableHead : Attribute.Attribute
	tableHead = class("hidden sm:table-header-group sm:bg-slate-100")

	tableBody : Attribute.Attribute
	tableBody = class("block space-y-3 sm:table-row-group sm:space-y-0 sm:divide-y sm:divide-slate-100 sm:bg-white")

	tableRow : Attribute.Attribute
	tableRow = class("block rounded-xl border border-slate-200 bg-white p-4 shadow-sm sm:table-row sm:rounded-none sm:border-0 sm:p-0 sm:shadow-none sm:transition sm:hover:bg-slate-50")

	## The record's identity: a card heading on a phone, an ordinary first
	## column on a wide screen.
	## From `sm` up on a touch device — a tablet — the row is a table row again,
	## but the record's link is still only as tall as its text. The extra
	## vertical padding keeps that tap comfortable without affecting a desktop.
	tableCellPrimary : Attribute.Attribute
	tableCellPrimary = class("block pb-2 text-base font-semibold sm:table-cell sm:whitespace-nowrap sm:px-4 sm:py-3 sm:text-sm sm:font-normal sm:pointer-coarse:py-4")

	tableCell : Attribute.Attribute
	tableCell = class("flex items-baseline gap-2 py-0.5 text-slate-700 sm:table-cell sm:whitespace-nowrap sm:px-4 sm:py-3")

	## The column name repeated inside its cell, so a card row stays readable
	## once the header row is hidden.
	cellLabel : Attribute.Attribute
	cellLabel = class("shrink-0 text-slate-400 sm:hidden")

	## The record's own link. On a phone it fills the card's width and takes a
	## comfortable height, so opening a record is a whole-line tap rather than a
	## press on a short run of text; from `sm` up it is ordinary cell text again.
	recordCardLink : Attribute.Attribute
	recordCardLink = class("-m-1 flex min-h-10 items-center gap-1 p-1 font-semibold text-blue-700 hover:underline sm:m-0 sm:inline sm:min-h-0 sm:p-0")

	recordCardChevron : Attribute.Attribute
	recordCardChevron = class("ml-auto h-5 w-5 shrink-0 text-slate-400 sm:hidden")

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

	tableActions : Attribute.Attribute
	tableActions = class("flex flex-wrap gap-2")

	emptyState : Attribute.Attribute
	emptyState = class("px-4 py-10 text-center text-sm text-slate-500")

	emptyStatePanel : Attribute.Attribute
	emptyStatePanel = class("rounded-xl border border-dashed border-slate-300 bg-white px-6 py-10 text-center sm:py-14")

	emptyStateIcon : Attribute.Attribute
	emptyStateIcon = class("mx-auto mb-3 inline-flex rounded-full bg-slate-100 p-3 text-slate-400")

	emptyStateIconGlyph : Attribute.Attribute
	emptyStateIconGlyph = class("h-6 w-6")

	emptyStateText : Attribute.Attribute
	emptyStateText = class("mx-auto max-w-sm text-pretty text-sm text-slate-600")

	emptyStateActions : Attribute.Attribute
	emptyStateActions = class("mt-4 flex justify-center")

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

	scannerPanel : Attribute.Attribute
	scannerPanel = class("mt-6 max-w-2xl rounded-xl border border-blue-200 bg-blue-50 p-5 shadow-sm")

	scannerForm : Attribute.Attribute
	scannerForm = class("mt-4")

	scannerPreview : Attribute.Attribute
	scannerPreview = class("mt-3 max-h-80 w-full rounded-lg border border-slate-300 bg-slate-950 object-contain")

	scannerError : Attribute.Attribute
	scannerError = class("mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-700")

	scannerSuccess : Attribute.Attribute
	scannerSuccess = class("mt-3 rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm font-medium text-emerald-800")

	scannerClientStatus : Attribute.Attribute
	scannerClientStatus = class("mt-3 text-sm font-medium text-slate-700 empty:hidden")

	scannerReview : Attribute.Attribute
	scannerReview = class("mt-4 rounded-lg border border-emerald-200 bg-white p-4")

	scannerReviewWarning : Attribute.Attribute
	scannerReviewWarning = class("mt-4 rounded-lg border border-amber-300 bg-amber-50 p-4")

	scannerReviewHeading : Attribute.Attribute
	scannerReviewHeading = class("font-semibold text-slate-900")

	scannerReviewLine : Attribute.Attribute
	scannerReviewLine = class("mt-2 whitespace-pre-line text-sm text-slate-700")

	scannerWarnings : Attribute.Attribute
	scannerWarnings = class("mt-1 list-disc space-y-1 pl-5 text-sm text-amber-900")

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

	contactActions : Attribute.Attribute
	contactActions = class("flex flex-wrap items-center justify-end gap-3")

	inlineForm : Attribute.Attribute
	inlineForm = class("mt-4 grid gap-3 rounded-lg bg-slate-50 p-4 sm:grid-cols-2")

	inlineFormAction : Attribute.Attribute
	inlineFormAction = class("self-start justify-self-start sm:self-end")

	checkboxLabel : Attribute.Attribute
	checkboxLabel = class("flex items-center gap-2 text-sm text-slate-700")

	fullWidthField : Attribute.Attribute
	fullWidthField = class("sm:col-span-2")

	dangerLinkButton : Attribute.Attribute
	dangerLinkButton = class("text-sm font-medium text-red-700 hover:underline")

	workGrid : Attribute.Attribute
	workGrid = class("mt-6 grid gap-4 sm:gap-6 lg:grid-cols-3")

	workBucket : Attribute.Attribute
	workBucket = class("rounded-xl border border-slate-200 bg-white p-4 shadow-sm sm:p-5")

	overdueBucket : Attribute.Attribute
	overdueBucket = class("rounded-xl border border-red-200 bg-red-50 p-4 shadow-sm sm:p-5")

	bucketHeader : Attribute.Attribute
	bucketHeader = class("flex items-center justify-between gap-3")

	bucketCount : Attribute.Attribute
	bucketCount = class("inline-flex h-6 min-w-6 items-center justify-center rounded-full bg-slate-100 px-2 text-xs font-semibold tabular-nums text-slate-700")

	overdueBucketCount : Attribute.Attribute
	overdueBucketCount = class("inline-flex h-6 min-w-6 items-center justify-center rounded-full bg-red-100 px-2 text-xs font-semibold tabular-nums text-red-800")

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

	taskMeta : Attribute.Attribute
	taskMeta = class("mt-2 space-y-1 text-sm text-slate-600")

	taskActions : Attribute.Attribute
	taskActions = class("mt-3")

	taskRequestStatus : Attribute.Attribute
	taskRequestStatus = class("htmx-indicator ml-2")

	activityMeta : Attribute.Attribute
	activityMeta = class("mt-1 text-xs text-slate-500")

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

## Controls take a comfortable minimum height wherever the pointer is coarse,
## and compact to their natural proportions only for a precise one. This keys
## off the input device rather than the viewport width, so a tablet gets touch
## sizing even though it is wider than the `sm` breakpoint.
buttonSizeClasses : Design.ButtonSize -> Str
buttonSizeClasses = |size|
	match size {
		Regular => "min-h-11 gap-2 px-4 py-2 text-sm pointer-fine:min-h-0"
		Small => "min-h-10 gap-1.5 px-3 py-1.5 text-xs pointer-fine:min-h-0"
		Full => "min-h-11 w-full gap-2 px-4 py-2 text-sm pointer-fine:min-h-0"
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
