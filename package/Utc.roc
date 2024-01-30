interface Utc
    exposes [
        Utc,
        toMillisSinceEpoch,
        fromMillisSinceEpoch,
        toNanosSinceEpoch,
        fromNanosSinceEpoch,
        deltaAsMillis,
        deltaAsNanos,
    ]
    imports []

## Stores a timestamp as nanoseconds since UNIX EPOCH
Utc := I128 implements [Inspect, Eq]

# Constant number of nanoseconds in a millisecond
nanosPerMilli = 1_000_000

## Convert Utc timestamp to milliseconds
toMillisSinceEpoch : Utc -> I128
toMillisSinceEpoch = \@Utc nanos ->
    nanos // nanosPerMilli

## Convert milliseconds to Utc timestamp
fromMillisSinceEpoch : I128 -> Utc
fromMillisSinceEpoch = \millis ->
    @Utc (millis * nanosPerMilli)

## Convert Utc timestamp to nanoseconds
toNanosSinceEpoch : Utc -> I128
toNanosSinceEpoch = \@Utc nanos ->
    nanos

## Convert nanoseconds to Utc timestamp
fromNanosSinceEpoch : I128 -> Utc
fromNanosSinceEpoch = @Utc

## Calculate milliseconds between two Utc timestamps
deltaAsMillis : Utc, Utc -> I128
deltaAsMillis = \@Utc first, @Utc second ->
    (Num.absDiff first second) // nanosPerMilli

## Calculate nanoseconds between two Utc timestamps
deltaAsNanos : Utc, Utc -> I128
deltaAsNanos = \@Utc first, @Utc second ->
    Num.absDiff first second