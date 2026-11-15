import Toybox.Lang;

// Kept free of Dc and ActivityMonitor so (:test) cases can call it directly.
module RidgelineRing {

    // RingSource values (resources/properties.xml). Append-only.
    const STEPS     = 0;
    const FLOORS    = 1;
    const INTENSITY = 2;
    const BATTERY   = 3;

    function isValidSource(id as Object or Null) as Lang.Boolean {
        return (id instanceof Lang.Number) && id >= STEPS && id <= BATTERY;
    }

    // [value, goal] ready for segments(). A null value is 0; a null or
    // non-positive goal means no data, which segments() draws as nothing.
    function progress(value as Lang.Numeric or Null,
            goal as Lang.Numeric or Null) as Lang.Array<Lang.Number> {
        if (goal == null || goal <= 0) {
            return [0, 0];
        }
        var v = (value == null) ? 0 : value.toNumber();
        return [v, goal.toNumber()];
    }

    // Integer division, so an exact multiple of the goal is sweep 0 of the
    // next lap rather than a float just under 360. The sweep is floored, not
    // rounded: 360 would make drawArc's endpoints equal and draw a full
    // circle before the goal. A sub-degree remainder is 0, so nothing draws.
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
