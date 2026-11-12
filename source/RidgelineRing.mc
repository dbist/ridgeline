using Toybox.Lang;

// Step-ring maths, kept free of Dc and ActivityMonitor so (:test) cases in
// RidgelineRingTests.mc can exercise it directly (issue #23).
module RidgelineRing {

    // Each full multiple of the goal is a lap. Returns [lap, sweep]: lap is
    // the number of completed laps, sweep is the current lap's progress in
    // whole degrees, 0..359. Integer maths throughout, so an exact multiple
    // of the goal is always sweep 0 of the next lap, never 359.99 of this one.
    //
    // The sweep is floored, not rounded, on purpose: drawArc draws a full
    // circle when start and end match, so 9,999 of 10,000 must stay 359, not
    // round to 360 and look like a finished lap. Under one degree is 0.
    function segments(steps as Lang.Number, goal as Lang.Number) as Lang.Array<Lang.Number> {
        if (goal <= 0 || steps <= 0) {
            return [0, 0];
        }
        return [steps / goal, ((steps % goal) * 360) / goal];
    }

    // drawArc end angle for a clockwise sweep from 12 o'clock (90 degrees).
    // For sweep 1..359 the result is never 90, so start never equals end.
    function endAngle(sweep as Lang.Number) as Lang.Number {
        return (90 - sweep + 360) % 360;
    }
}
