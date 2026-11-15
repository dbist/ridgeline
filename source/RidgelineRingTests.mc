import Toybox.Lang;
import Toybox.Test;

// (:test) code is left out of normal builds. How to run: CONTRIBUTING.md,
// "Running the unit tests".

(:test)
function ringNoStepsDrawsNothing(logger as Test.Logger) as Lang.Boolean {
    var s = RidgelineRing.segments(0, 10000);
    return s[0] == 0 && s[1] == 0;
}

// 1-27 steps of 10,000 is under a degree, so no arc (not a 1-degree tick).
(:test)
function ringSubDegreeSweepIsZero(logger as Test.Logger) as Lang.Boolean {
    var a = RidgelineRing.segments(1, 10000);
    var b = RidgelineRing.segments(27, 10000);
    return a[0] == 0 && a[1] == 0 && b[0] == 0 && b[1] == 0;
}

(:test)
function ringFirstWholeDegree(logger as Test.Logger) as Lang.Boolean {
    var s = RidgelineRing.segments(28, 10000);  // 1.008 degrees
    return s[0] == 0 && s[1] == 1;
}

(:test)
function ringHalfway(logger as Test.Logger) as Lang.Boolean {
    var s = RidgelineRing.segments(5000, 10000);
    return s[0] == 0 && s[1] == 180;
}

// Just short of the goal: sweep is floored to 359, never 360. 360 would
// make drawArc's start and end equal, which draws a full circle (issue #12).
(:test)
function ringJustBeforeGoal(logger as Test.Logger) as Lang.Boolean {
    var s = RidgelineRing.segments(9999, 10000);
    return s[0] == 0 && s[1] == 359;
}

(:test)
function ringExactGoalIsNewLap(logger as Test.Logger) as Lang.Boolean {
    var s = RidgelineRing.segments(10000, 10000);
    return s[0] == 1 && s[1] == 0;
}

// Second lap: 10,001-10,027 is likewise under a degree of the new lap.
(:test)
function ringSubDegreePastGoal(logger as Test.Logger) as Lang.Boolean {
    var s = RidgelineRing.segments(10027, 10000);
    return s[0] == 1 && s[1] == 0;
}

(:test)
function ringExactMultiplesAreWholeLaps(logger as Test.Logger) as Lang.Boolean {
    for (var lap = 1; lap <= 10; lap++) {
        var s = RidgelineRing.segments(lap * 7000, 7000);
        if (s[0] != lap || s[1] != 0) {
            logger.error("lap " + lap + " gave " + s);
            return false;
        }
    }
    return true;
}

(:test)
function ringBadGoalDrawsNothing(logger as Test.Logger) as Lang.Boolean {
    var a = RidgelineRing.segments(500, 0);
    var b = RidgelineRing.segments(500, -1);
    return a[1] == 0 && b[1] == 0;
}

(:test)
function ringEndAngle(logger as Test.Logger) as Lang.Boolean {
    return RidgelineRing.endAngle(1) == 89
        && RidgelineRing.endAngle(90) == 0
        && RidgelineRing.endAngle(180) == 270
        && RidgelineRing.endAngle(359) == 91;
}

// For every possible sweep the arc's end differs from its start (90).
(:test)
function ringEndNeverEqualsStart(logger as Test.Logger) as Lang.Boolean {
    for (var sweep = 1; sweep <= 359; sweep++) {
        if (RidgelineRing.endAngle(sweep) == 90) {
            logger.error("sweep " + sweep + " ends at the start angle");
            return false;
        }
    }
    return true;
}

// RingSource progress (issue #40): null value, null goal, zero goal and a
// value past the goal.
(:test)
function ringProgressNullValueIsZero(logger as Test.Logger) as Lang.Boolean {
    var p = RidgelineRing.progress(null, 10);
    var s = RidgelineRing.segments(p[0], p[1]);
    return p[0] == 0 && p[1] == 10 && s[0] == 0 && s[1] == 0;
}

(:test)
function ringProgressNullGoalDrawsNothing(logger as Test.Logger) as Lang.Boolean {
    var p = RidgelineRing.progress(12, null);
    var s = RidgelineRing.segments(p[0], p[1]);
    return s[0] == 0 && s[1] == 0;
}

(:test)
function ringProgressZeroGoalDrawsNothing(logger as Test.Logger) as Lang.Boolean {
    var a = RidgelineRing.progress(12, 0);
    var b = RidgelineRing.progress(12, -5);
    var sa = RidgelineRing.segments(a[0], a[1]);
    var sb = RidgelineRing.segments(b[0], b[1]);
    return sa[0] == 0 && sa[1] == 0 && sb[0] == 0 && sb[1] == 0;
}

(:test)
function ringProgressPastGoalLaps(logger as Test.Logger) as Lang.Boolean {
    var p = RidgelineRing.progress(15, 10);   // 1.5 x the goal
    var s = RidgelineRing.segments(p[0], p[1]);
    return s[0] == 1 && s[1] == 180;
}

// Battery is a Float percentage against a goal of 100.
(:test)
function ringProgressBatteryHalf(logger as Test.Logger) as Lang.Boolean {
    var p = RidgelineRing.progress(50.0, 100);
    var s = RidgelineRing.segments(p[0], p[1]);
    return s[0] == 0 && s[1] == 180;
}

(:test)
function ringSourceValidation(logger as Test.Logger) as Lang.Boolean {
    return RidgelineRing.isValidSource(0) && RidgelineRing.isValidSource(3)
        && !RidgelineRing.isValidSource(4) && !RidgelineRing.isValidSource(-1)
        && !RidgelineRing.isValidSource(null) && !RidgelineRing.isValidSource("1");
}

// A missing or non-positive goal from the watch falls back to Garmin's
// default for that source, so every source shows progress (PR #58 review).
(:test)
function ringGoalFallbacks(logger as Test.Logger) as Lang.Boolean {
    return RidgelineRing.goalOr(null, RidgelineRing.FLOORS_GOAL) == 10
        && RidgelineRing.goalOr(0, RidgelineRing.INTENSITY_GOAL) == 150
        && RidgelineRing.goalOr(-3, RidgelineRing.STEP_GOAL) == 10000
        && RidgelineRing.goalOr(25, RidgelineRing.FLOORS_GOAL) == 25;
}

(:test)
function ringFloorsWithoutGoalUsesDefault(logger as Test.Logger) as Lang.Boolean {
    var p = RidgelineRing.progress(5, RidgelineRing.goalOr(null, RidgelineRing.FLOORS_GOAL));
    var s = RidgelineRing.segments(p[0], p[1]);
    return s[0] == 0 && s[1] == 180;
}
