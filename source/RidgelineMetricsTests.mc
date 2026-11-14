using Toybox.Lang;
using Toybox.Test;

// Cache freshness for the per-minute metric reads (issue #54). (:test) code
// is left out of normal builds; see CONTRIBUTING.md, "Running the unit tests".

(:test)
function cacheEmptyIsStale(logger as Test.Logger) as Lang.Boolean {
    return !RidgelineMetrics.isFresh(1000, null);
}

(:test)
function cacheFreshUntilSixtySeconds(logger as Test.Logger) as Lang.Boolean {
    return RidgelineMetrics.isFresh(1000, 1000) &&
        RidgelineMetrics.isFresh(1059, 1000) &&
        !RidgelineMetrics.isFresh(1060, 1000);
}

// The clock moved back after the fetch: stale, even though now - at is
// below CACHE_SECS.
(:test)
function cacheStaleWhenClockMovesBack(logger as Test.Logger) as Lang.Boolean {
    return !RidgelineMetrics.isFresh(999, 1000) &&
        !RidgelineMetrics.isFresh(1000 - 3600, 1000) &&
        !RidgelineMetrics.sunCacheValid(999, 1000, 2000, true, true);
}

(:test)
function sunCacheValidBeforeEvent(logger as Test.Logger) as Lang.Boolean {
    return RidgelineMetrics.sunCacheValid(1030, 1000, 1031, true, true);
}

// At the event itself the cache is stale, so RISE/SET flips on that frame
// rather than up to a minute later.
(:test)
function sunCacheStaleOnceEventPasses(logger as Test.Logger) as Lang.Boolean {
    return !RidgelineMetrics.sunCacheValid(1031, 1000, 1031, true, true);
}

// "--" has no event time: only age expires it, so a location that arrives
// later shows within a minute.
(:test)
function sunCacheWithoutEventExpiresByAge(logger as Test.Logger) as Lang.Boolean {
    return RidgelineMetrics.sunCacheValid(1059, 1000, null, true, true) &&
        !RidgelineMetrics.sunCacheValid(1060, 1000, null, true, true);
}

(:test)
function sunCacheStaleWhenClockModeChanges(logger as Test.Logger) as Lang.Boolean {
    return !RidgelineMetrics.sunCacheValid(1010, 1000, 2000, true, false);
}
