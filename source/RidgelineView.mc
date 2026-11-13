using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.Activity;
using Toybox.Application;

class RidgelineView extends WatchUi.WatchFace {

    hidden const LABEL_COLOR = 0x555555;
    hidden const DIM_COLOR   = 0x333333;

    // Step-ring colours for each multiple of the goal past the first: light
    // green, blue, purple, then repeat. All are in the 64-colour MIP palette.
    hidden const LAP_COLORS  = [0x55FF55, 0x00AAFF, 0xAA55FF];

    hidden var mLowPower  = false;
    hidden var mAccent    = 0xFF5500;
    hidden var mShowSecs  = true;
    hidden var mShowRing  = true;
    hidden var mLapColors = LAP_COLORS;
    hidden var mColumns as Lang.Array<Lang.Number> = RidgelineMetrics.COLUMN_DEFAULTS;
    // Tap targets for the metric columns, from the last onUpdate:
    // [[left, top, right, bottom, complicationType or null], ...].
    hidden var mHitBoxes as Lang.Array = [];

    function initialize() {
        WatchFace.initialize();
        loadSettings();
    }

    function onLayout(dc) {
    }

    function loadSettings() {
        mAccent   = getSetting("AccentColor", 0xFF5500);
        mShowSecs = getSetting("ShowSeconds", true);
        mShowRing = getSetting("ShowGoalRing", true);

        // Which metric each column shows; an unknown id keeps the default.
        var keys = RidgelineMetrics.COLUMN_KEYS;
        mColumns = [];
        for (var i = 0; i < keys.size(); i++) {
            var id = getSetting(keys[i], RidgelineMetrics.COLUMN_DEFAULTS[i]);
            mColumns.add(RidgelineMetrics.isValid(id) ? id : RidgelineMetrics.COLUMN_DEFAULTS[i]);
        }

        // Drop a lap colour that matches the accent, or the first lap past the
        // goal would look identical to the progress towards it.
        mLapColors = [];
        for (var i = 0; i < LAP_COLORS.size(); i++) {
            if (LAP_COLORS[i] != mAccent) {
                mLapColors.add(LAP_COLORS[i]);
            }
        }
    }

    hidden function getSetting(key, fallback) {
        var value = null;
        try {
            value = Application.Properties.getValue(key);
        } catch (e) {
            value = null;
        }
        return (value == null) ? fallback : value;
    }

    // ---------------------------------------------------------------- draw

    function onUpdate(dc) {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (mShowRing) {
            drawStepRing(dc, cx, cy, w);
        }

        drawDate(dc, cx, h);
        var timeBox = drawTime(dc, cx, cy, w, h);
        if (mShowSecs && !mLowPower) {
            drawSeconds(dc, timeBox, w);
        }
        drawMetrics(dc, w, h);
        drawNotificationDot(dc, cx, h);
    }

    hidden function drawStepRing(dc, cx, cy, w) {
        var info    = ActivityMonitor.getInfo();
        var steps   = (info.steps == null) ? 0 : info.steps;
        var goal    = (info.stepGoal == null || info.stepGoal <= 0) ? 10000 : info.stepGoal;
        var pct     = steps.toFloat() / goal.toFloat();
        var radius  = (w / 2) - 5;

        dc.setPenWidth(6);
        dc.setColor(DIM_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, radius);

        if (pct <= 0.0) {
            return;
        }

        // Each full multiple of the goal is a lap. A completed lap stays as a
        // full circle in its own colour; the next lap sweeps over it.
        var lap  = pct.toNumber();
        var frac = pct - lap;

        if (lap > 0) {
            dc.setColor(ringColor(lap - 1), Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy, radius);
        }

        // drawArc truncates angles and draws a full circle when they match,
        // so keep the sweep an integer in 1..359.
        var sweep = (360.0 * frac).toNumber();
        if (sweep < 1) {
            return;
        }

        // 90 degrees is 12 o'clock; sweep clockwise.
        dc.setColor(ringColor(lap), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, (90 - sweep + 360) % 360);
    }

    // Lap 0 (working towards the goal) is the accent; every lap past the goal
    // cycles through mLapColors.
    hidden function ringColor(lap) {
        if (lap == 0) {
            return mAccent;
        }
        return mLapColors[(lap - 1) % mLapColors.size()];
    }

    hidden function drawDate(dc, cx, h) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var text = Lang.format("$1$  $2$ $3$", [
            now.day_of_week.toUpper(),
            now.day.format("%02d"),
            now.month.toUpper()
        ]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.20, Graphics.FONT_SMALL, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Returns [rightEdgeX, centreY, fontHeight] for the time block, so the
    // seconds can be placed against it without re-measuring.
    hidden function drawTime(dc, cx, cy, w, h) {
        var clock = System.getClockTime();
        var hour  = clock.hour;

        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }

        var text = Lang.format("$1$:$2$", [
            System.getDeviceSettings().is24Hour ? hour.format("%02d") : hour.format("%d"),
            clock.min.format("%02d")
        ]);

        var font = Graphics.FONT_NUMBER_THAI_HOT;
        if (dc.getFontHeight(font) > (h * 0.40) ||
            dc.getTextWidthInPixels(text, font) > (w * 0.88)) {
            font = Graphics.FONT_NUMBER_HOT;
        }

        var baseY = cy - (h * 0.05);
        var textW = dc.getTextWidthInPixels(text, font);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, baseY, font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        return [ cx + (textW / 2), baseY, dc.getFontHeight(font) ];
    }

    // Seconds sit in the lower right of the time block, not beneath it. On a
    // 280px screen the time font is 107px tall and the metric rows start at
    // 0.73*h, leaving ~15px of clear space below the digits -- smaller than
    // FONT_XTINY. There is no font that fits there, so the seconds go beside
    // the time instead.
    hidden function drawSeconds(dc, timeBox, w) {
        var secs   = System.getClockTime().sec.format("%02d");
        var rightX = timeBox[0];
        var baseY  = timeBox[1];
        var timeH  = timeBox[2];

        var font  = Graphics.FONT_TINY;
        var secsW = dc.getTextWidthInPixels(secs, font);
        var secsH = dc.getFontHeight(font);

        // Bottom-align against the digits rather than centring on them.
        var y = baseY + (timeH / 2) - (secsH / 2) - 6;

        var x = rightX + 6;
        if (x + secsW > w - 8) {
            x = w - 8 - secsW;
        }

        dc.setColor(mAccent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, secs,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawMetrics(dc, w, h) {
        var valueFont = Graphics.FONT_TINY;
        var labelFont = Graphics.FONT_XTINY;

        // Stack the label under the value using the real font boxes rather
        // than a second magic fraction. FONT_TINY and FONT_XTINY differ per
        // device, and the old h*0.822 left the two rows touching at 280px.
        var valueY = h * 0.730;
        var labelY = valueY
            + (dc.getFontHeight(valueFont) / 2)
            + (dc.getFontHeight(labelFont) / 2)
            + 3;

        // Outer columns sit at 0.26/0.74, not 0.23/0.77: this row is low
        // enough that the round bezel clips text pushed further out.
        var xs = [w * 0.26, w * 0.50, w * 0.74];

        var cols = [];
        for (var i = 0; i < xs.size(); i++) {
            cols.add(RidgelineMetrics.read(mColumns[i]));
        }

        // Try full values, then 10,000+ as "12.3k", then those in the label
        // font. The last pass is drawn even if it is still tight.
        var passes = [[0, valueFont], [3, valueFont], [3, labelFont]];
        var places = null;
        var font   = valueFont;
        for (var k = 0; k < passes.size() && places == null; k++) {
            var pass = passes[k] as Lang.Array;
            font = pass[1];
            places = placeColumns(dc, cols, xs, w, h, valueY, labelY,
                pass[0] as Lang.Number, font, labelFont, k == passes.size() - 1);
        }

        // Hold targets span the value and label lines. Neighbouring boxes
        // meet at the midpoint between the columns as placed, so they never
        // overlap even after placeColumns moves an outer column inward. The
        // outer edges reach half the default column pitch (0.24w) outward.
        var top    = valueY - (dc.getFontHeight(font) / 2);
        var bottom = labelY + (dc.getFontHeight(labelFont) / 2);
        var halfW  = (w * 0.24) / 2;
        var last   = cols.size() - 1;
        var centers = [];
        for (var i = 0; i <= last; i++) {
            centers.add(((places as Lang.Array)[i] as Lang.Array)[0]);
        }
        mHitBoxes = [];

        for (var i = 0; i <= last; i++) {
            var m = cols[i] as Lang.Array;
            var p = (places as Lang.Array)[i] as Lang.Array;
            drawColumn(dc, p[0], valueY, labelY, p[1], m[1], m[2],
                font, labelFont);
            var boxL = (i == 0)    ? centers[i] - halfW : (centers[i - 1] + centers[i]) / 2;
            var boxR = (i == last) ? centers[i] + halfW : (centers[i] + centers[i + 1]) / 2;
            mHitBoxes.add([boxL, top, boxR, bottom,
                RidgelineMetrics.complicationType(mColumns[i], m[1] as Lang.String)]);
        }
    }

    // The complication behind the metric column at (x, y), or null.
    function complicationAt(x, y) {
        for (var i = 0; i < mHitBoxes.size(); i++) {
            var b = mHitBoxes[i] as Lang.Array;
            if (x >= b[0] && x <= b[2] && y >= b[1] && y <= b[3]) {
                return b[4];
            }
        }
        return null;
    }

    // Half-width of the area inside the step ring (inner edge less a margin)
    // at height y; text lines are tested at their baseline, where the glyphs
    // end, rather than their centre.
    hidden function ringHalfWidth(w, h, y) {
        var inner = (w / 2) - 5 - 3 - 4;
        var dy = (y - (h / 2)).abs();
        return (inner > dy) ? Math.sqrt((inner * inner) - (dy * dy)) : 0;
    }

    // Positions each column using value text index textIdx (0 full, 3
    // compact) of a RidgelineMetrics.read() result. An outer column moves
    // inward until both its value and its label fit inside the ring. Returns
    // [[x, valueText], ...], or null if neighbours (whichever of value or
    // label is wider) come within a space of each other, unless force.
    hidden function placeColumns(dc, cols as Lang.Array, xs as Lang.Array,
            w, h, valueY, labelY, textIdx as Lang.Number, valueFont, labelFont,
            force as Lang.Boolean) {
        var valueBase = valueY + (dc.getFontHeight(valueFont) / 2)
            - Graphics.getFontDescent(valueFont);
        var labelBase = labelY + (dc.getFontHeight(labelFont) / 2)
            - Graphics.getFontDescent(labelFont);
        var valueHalf = ringHalfWidth(w, h, valueBase);
        var labelHalf = ringHalfWidth(w, h, labelBase);
        var cx  = w / 2;
        var gap = dc.getTextWidthInPixels(" ", labelFont);
        var last = cols.size() - 1;

        var places = [];
        var prevRight = null;
        for (var i = 0; i <= last; i++) {
            var m    = cols[i] as Lang.Array;
            var text = m[textIdx] as Lang.String;
            var valW = dc.getTextWidthInPixels(text, valueFont);
            var lblW = dc.getTextWidthInPixels(m[1] as Lang.String, labelFont);
            var colW = (lblW > valW) ? lblW : valW;

            var x = xs[i] as Lang.Float;
            if (i == 0) {
                var minX = cx - valueHalf + (valW / 2);
                var minL = cx - labelHalf + (lblW / 2);
                if (minL > minX) { minX = minL; }
                if (x < minX) { x = minX; }
            } else if (i == last) {
                var maxX = cx + valueHalf - (valW / 2);
                var maxL = cx + labelHalf - (lblW / 2);
                if (maxL < maxX) { maxX = maxL; }
                if (x > maxX) { x = maxX; }
            }

            if (!force && prevRight != null && x - (colW / 2) < prevRight + gap) {
                return null;
            }
            prevRight = x + (colW / 2);
            places.add([x, text]);
        }
        return places;
    }

    hidden function drawColumn(dc, x, valueY, labelY, value, label, color, valueFont, labelFont) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, valueY, valueFont, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(LABEL_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, labelY, labelFont, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawNotificationDot(dc, cx, h) {
        var count = System.getDeviceSettings().notificationCount;
        if (count == null || count <= 0) {
            return;
        }
        dc.setColor(mAccent, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, h * 0.115, 4);
    }

    // ------------------------------------------------------------ lifecycle

    function onEnterSleep() {
        mLowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() {
        mLowPower = false;
        WatchUi.requestUpdate();
    }
}
