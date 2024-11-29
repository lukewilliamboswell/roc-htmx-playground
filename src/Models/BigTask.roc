module [
    BigTask,
    Date,
    Status,
    Priority,
    parseDate,
    parseStatus,
    parsePriority,
    dateToStr,
    priorityToStr,
    statusToStr,
    statusOptions,
    statusOptionIndex,
]

Date : [NotSet, Simple { year : I64, month : I64, day : I64 }, Invalid Str]

dateToStr : Date -> Str
dateToStr = \date ->

    # we need to ensure we add the leading zero for yyyy-mm-dd
    numToStr = \i64 ->
        if i64 < 10 then
            "0$(Num.toStr i64)"
        else
            Num.toStr i64

    when date is
        NotSet -> "Not Set"
        Simple { year, month, day } -> "$(numToStr year)-$(numToStr month)-$(numToStr day)"
        Invalid value -> "INVALID GOT '$(value)'"

# Not a serious implementation, just for demonstration purposes
parseDate : Str -> Result Date [InvalidDate Str]
parseDate = \date ->
    validYear = \y -> y > 1970 && y < 3000
    validMonth = \m -> m > 0 && m < 13
    validDay = \d -> d > 0 && d < 32

    isFourChars = \str -> List.len (Str.toUtf8 str) == 4
    isTwoChars = \str -> List.len (Str.toUtf8 str) == 2

    # Format: yyyy-mm-dd
    when Str.splitOn date "-" is
        [""] -> Ok NotSet
        [yyyy, mm, dd] if isFourChars yyyy && isTwoChars mm && isTwoChars dd ->
            when (Str.toI64 yyyy, Str.toI64 mm, Str.toI64 dd) is
                (Ok year, Ok month, Ok day) if validYear year && validMonth month && validDay day -> Ok (Simple { year, month, day })
                _ -> Err (InvalidDate date)

        _ -> Err (InvalidDate date)

expect parseDate "2021-01-01" == Ok (Simple { year: 2021, month: 1, day: 1 })
expect parseDate "01-01-2024" == Err (InvalidDate "01-01-2024")
expect parseDate "" == Ok NotSet

Status : [Raised, Completed, Deferred, Approved, InProgress, Invalid Str]

statusToStr : Status -> Str
statusToStr = \s ->
    when s is
        Raised -> "Raised"
        Completed -> "Completed"
        Deferred -> "Deferred"
        Approved -> "Approved"
        InProgress -> "In-Progress"
        Invalid value -> "INVALID GOT '$(value)'"

statusOptions = ["Raised","Completed","Deferred","Approved","In-Progress"]
statusOptionIndex = \str ->
    when str is
        "Raised" -> Ok 0
        "Completed" -> Ok 1
        "Deferred" -> Ok 2
        "Approved" -> Ok 3
        "In-Progress" -> Ok 4
        _ -> Err (InvalidStatus str)

parseStatus : Str -> Result Status [InvalidStatus Str]
parseStatus = \status ->
    when status is
        "Raised" -> Ok Raised
        "Completed" -> Ok Completed
        "Deferred" -> Ok Deferred
        "Approved" -> Ok Approved
        "In-Progress" -> Ok InProgress
        _ -> Err (InvalidStatus status)

expect parseStatus "Raised" == Ok Raised
expect parseStatus "Completed" == Ok Completed
expect parseStatus "Deferred" == Ok Deferred
expect parseStatus "Approved" == Ok Approved
expect parseStatus "In-Progress" == Ok InProgress
expect parseStatus "definitely not valid" == Err (InvalidStatus "definitely not valid")

Priority : [Low, Medium, High, Invalid Str]

priorityToStr : Priority -> Str
priorityToStr = \p ->
    when p is
        Low -> "Low"
        Medium -> "Medium"
        High -> "High"
        Invalid value -> "INVALID GOT '$(value)'"

parsePriority : Str -> Priority
parsePriority = \priority ->
    when priority is
        "Low" -> Low
        "Medium" -> Medium
        "High" -> High
        _ -> Invalid priority

expect parsePriority "Low" == Low
expect parsePriority "Medium" == Medium
expect parsePriority "High" == High
expect parsePriority "" == Invalid ""

BigTask : {
    id : I64,
    referenceId : Str,
    customerReferenceId : Str,
    dateCreated : Date,
    dateModified : Date,
    title : Str,
    description : Str,
    status : Status,
    priority : Priority,
    scheduledStartDate : Date,
    scheduledEndDate : Date,
    actualStartDate : Date,
    actualEndDate : Date,
    systemName : Str,
    location : Str,
    fileReference : Str,
    comments : Str,
}
