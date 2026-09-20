using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.Activity;
using Toybox.Application;

class RidgelineView extends WatchUi.WatchFace {

    hidden const LABEL_COLOR = 0x555555;
    hidden const DIM_COLOR   = 0x333333;
    hidden const LOW_BATTERY = 0xFF0000;

    hidden var mLowPower  = false;
    hidden var mAccent    = 0xFF5500;
    hidden var mShowSecs  = true;
    hidden var mShowRing  = true;

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
        var timeBottom = drawTime(dc, cx, cy, w, h);
        if (mShowSecs && !mLowPower) {
            drawSeconds(dc, cx, timeBottom);
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

        dc.setColor(mAccent, Graphics.COLOR_TRANSPARENT);
        if (pct >= 1.0) {
            dc.drawCircle(cx, cy, radius);
            return;
        }

        // 90 degrees is 12 o'clock; sweep clockwise.
        var endDeg = 90 - (360.0 * pct);
        while (endDeg < 0) { endDeg += 360; }
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, endDeg.toNumber());
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

    // Returns the y coordinate of the bottom of the time block.
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
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, baseY, font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        return baseY + (dc.getFontHeight(font) / 2);
    }

    hidden function drawSeconds(dc, cx, topY) {
        var secs = System.getClockTime().sec.format("%02d");
        dc.setColor(mAccent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, topY + 2, Graphics.FONT_TINY, secs,
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawMetrics(dc, w, h) {
        var valueY = h * 0.750;
        var labelY = h * 0.822;

        var info = ActivityMonitor.getInfo();
        var steps = (info.steps == null) ? 0 : info.steps;

        var battery = System.getSystemStats().battery;
        var batteryColor = (battery <= 15) ? LOW_BATTERY : Graphics.COLOR_WHITE;

        var hr = currentHeartRate();
        var hrText = (hr == null) ? "--" : hr.format("%d");

        drawColumn(dc, w * 0.23, valueY, labelY, hrText, "BPM", Graphics.COLOR_WHITE);
        drawColumn(dc, w * 0.50, valueY, labelY, steps.format("%d"), "STEPS", Graphics.COLOR_WHITE);
        drawColumn(dc, w * 0.77, valueY, labelY, battery.format("%d") + "%", "BATT", batteryColor);
    }

    hidden function drawColumn(dc, x, valueY, labelY, value, label, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, valueY, Graphics.FONT_TINY, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(LABEL_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, labelY, Graphics.FONT_XTINY, label,
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

    // ------------------------------------------------------------- helpers

    hidden function currentHeartRate() {
        var activity = Activity.getActivityInfo();
        if (activity != null && activity.currentHeartRate != null) {
            return activity.currentHeartRate;
        }

        try {
            var history = ActivityMonitor.getHeartRateHistory(1, true);
            if (history != null) {
                var sample = history.next();
                if (sample != null &&
                    sample.heartRate != null &&
                    sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    return sample.heartRate;
                }
            }
        } catch (e) {
            // SensorHistory unavailable on this device.
        }

        return null;
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
