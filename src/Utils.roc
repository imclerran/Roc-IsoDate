interface Utils
    exposes [
        unwrap,
        numDaysSinceEpoch,
        numDaysSinceEpochToYear,
        #numDaysSinceEpochToYMD,
        daysToNanos,
        splitStrAtIndex,
        splitStrAtIndices,
        calendarWeekToDaysInYear,
    ]
    imports [
        Const.{
            epochYear, 
            epochWeekOffset,
            secondsPerDay,
            nanosPerSecond,
            daysPerWeek,
            leapInterval,
            leapException,
            leapNonException,
            monthDays,
        },
    ]

unwrap : [Ok a, Err _], Str -> a
unwrap = \result, message ->
    when result is
        Ok x -> x
        Err _ -> crash message

splitStrAtIndex = \str, index -> splitStrAtIndices str [index]

expect splitStrAtIndex "abc" 0 == ["abc"]
expect splitStrAtIndex "abc" 1 == ["a", "bc"]
expect splitStrAtIndex "abc" 3 == ["abc"]

splitStrAtIndices = \str, indices ->
    Str.walkUtf8WithIndex 
        str
        [""]
        (\strList, byte, i ->
            char = unwrap (Str.fromUtf8 [byte]) "splitStrAtIndices: Invalid UTF-8 byte"
            if List.contains indices i then
                if i == 0 then
                    [char]
                else
                    List.append strList char
            else
                strs = List.takeFirst strList (List.len strList - 1)
                lastStr = unwrap (List.last strList) "splitStrAtIndices: List should always have last element"
                List.append strs (Str.concat lastStr char)
        )

expect splitStrAtIndices "abc" [1, 2] == ["a", "b", "c"]


isLeapYear = \year ->
    if year % leapInterval == 0 then
        if year % leapNonException == 0 then
            Bool.true
        else if year % leapException == 0 then
            Bool.false
        else 
            Bool.true
    else
        Bool.false

numLeapYearsSinceEpoch : U64, [IncludeCurrent, ExcludeCurrent] -> U64
numLeapYearsSinceEpoch = \year, inclusive ->
    years =
        when inclusive is  
            IncludeCurrent -> List.range { start: At epochYear, end: At year }
            ExcludeCurrent -> List.range { start: At epochYear, end: Before year }
    Num.intCast (List.countIf years isLeapYear) # TODO: Remove intCast call after Nat type removal from language

numDaysSinceEpoch: {year: U64, month? U64, day? U64} -> U64
numDaysSinceEpoch = \{year, month? 1, day? 1} ->
    numLeapYears = numLeapYearsSinceEpoch year ExcludeCurrent
    daysInYears = numLeapYears * 366 + (year - epochYear - numLeapYears) * 365
    isLeap = isLeapYear year
    daysInMonths = List.sum (
        List.map (List.range { start: At 1, end: Before month }) 
        (\mapMonth -> 
            unwrap (monthDays {month: mapMonth, isLeap}) "numDaysSinceEpochToYMD: Invalid month"
        ), 
    )
    daysInYears + daysInMonths + day - 1

# IMPORTANT
# Source of bug here:
# If next line is commented out, the compiler crashes with:
# thread 'main' panicked at 'Error in alias analysis: error in module ModName("UserApp"), function definition FuncName("\x11\x00\x00\x00\x02\x00\x00\x00\xcbr?\x05\x92\xae\x19\x92"), definition of value binding ValueId(3): expected type '(((), (), ()),)', found type '((),)'', crates/compiler/gen_llvm/src/llvm/build.rs:5761:19
# if not commented out, the comiler says optional record fields are missing.
expect numDaysSinceEpoch {year: 2024} == 19723

numDaysSinceEpochToYear = \year ->
    numDaysSinceEpoch {year}

expect numDaysSinceEpochToYear 1970 == 0
expect numDaysSinceEpochToYear 1971 == 365
expect numDaysSinceEpochToYear 1972 == 365 + 365
expect numDaysSinceEpochToYear 1973 == 365 + 365 + 366
expect numDaysSinceEpochToYear 2024 == 19723

# numDaysSinceEpochToYMD = \year, month, day ->
#     numLeapYears = numLeapYearsSinceEpoch year ExcludeCurrent
#     daysInYears = numLeapYears * 366 + (year - epochYear - numLeapYears) * 365
#     isLeap = isLeapYear year
#     daysInMonths = List.sum (
#         List.map (List.range { start: At 1, end: Before month }) 
#         (\mapMonth -> unwrap (monthDays {month: mapMonth, isLeap}) "numDaysSinceEpochToYMD: Invalid month"), 
#     )
#     daysInYears + daysInMonths + day - 1

expect numDaysSinceEpoch {year: 1970, month: 12, day: 31} == 365 - 1
expect numDaysSinceEpoch {year: 1971, month: 1, day: 2} == 365 + 1
expect numDaysSinceEpoch {year: 2024, month: 1, day: 1} == 19723
expect numDaysSinceEpoch {year: 2024, month: 2, day: 1} == 19723 + 31
expect numDaysSinceEpoch {year: 2024, month: 12, day: 31} == 19723 + 366 - 1

daysToNanos = \days ->
    days * secondsPerDay * nanosPerSecond |> Num.toU128

calendarWeekToDaysInYear = \week, year->
    # Week 1 of a year is the first week with a majority of its days in that year
    # https://en.wikipedia.org/wiki/ISO_week_date#First_week
    lengthOfMaybeFirstWeek = epochWeekOffset - (numDaysSinceEpochToYear year) % 7
    if lengthOfMaybeFirstWeek >= 4 && week == 1 then
        0
    else
        (week - 1) * daysPerWeek + lengthOfMaybeFirstWeek

expect calendarWeekToDaysInYear 1 1970  == 0
expect calendarWeekToDaysInYear 1 1971 == 3
expect calendarWeekToDaysInYear 1 1972 == 2
expect calendarWeekToDaysInYear 1 1973 == 0
expect calendarWeekToDaysInYear 2 2024 == 7