using Toybox.Lang;
using Toybox.Test;

// Unit tests for RidgelineRing. (:test) code is left out of normal builds.
// Run locally (needs the simulator running):
//   monkeyc -d enduro3 -f monkey.jungle -y <key> -t -o build/RidgelineTest.prg
//   monkeydo build/RidgelineTest.prg enduro3 -t

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
