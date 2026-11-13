using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.SensorHistory;
using Toybox.System;

// The metrics a column can show (issue #20), and how to read each one.
//
// Ids are stored in the LeftMetric/MiddleMetric/RightMetric properties, so
// they are append-only: never renumber or reuse one, or a saved choice
// silently changes meaning. Keep settings.xml's list entries in step.
module RidgelineMetrics {

    const HEART_RATE   = 0;
    const STEPS        = 1;
    const BATTERY      = 2;
    const BODY_BATTERY = 3;
    const STRESS       = 4;
    const CALORIES     = 5;
    const FLOORS       = 6;
    const INTENSITY    = 7;

    const COLUMN_KEYS     = ["LeftMetric", "MiddleMetric", "RightMetric"];
    const COLUMN_DEFAULTS = [HEART_RATE, STEPS, BATTERY];

    const LOW_BATTERY = 0xFF0000;

    // Picker order: what the menu lists, top to bottom.
    function ids() as Lang.Array<Lang.Number> {
        return [HEART_RATE, STEPS, BATTERY, BODY_BATTERY, STRESS, CALORIES,
                FLOORS, INTENSITY];
    }

    function names() as Lang.Array<Lang.ResourceId> {
        return [
            Rez.Strings.MetricHeartRate, Rez.Strings.MetricSteps,
            Rez.Strings.MetricBattery, Rez.Strings.MetricBodyBattery,
            Rez.Strings.MetricStress, Rez.Strings.MetricCalories,
            Rez.Strings.MetricFloors, Rez.Strings.MetricIntensity
        ];
    }

    function columnTitles() as Lang.Array<Lang.ResourceId> {
        return [Rez.Strings.LeftMetricTitle, Rez.Strings.MiddleMetricTitle,
                Rez.Strings.RightMetricTitle];
    }

    function isValid(id) as Lang.Boolean {
        return (id instanceof Lang.Number) && id >= 0 && id <= INTENSITY;
    }

    // Labels stay within five characters so three columns fit.
    function read(id as Lang.Number) as Lang.Array {
        var m = readFull(id);
        return [m[0], m[1], m[2], compact(m[0])];
    }

    // "12345" -> "12.3k", "123456" -> "123k"; anything shorter, or not a
    // plain number, unchanged.
    function compact(text as Lang.String) as Lang.String {
        var n = text.toNumber();
        if (n == null || n < 10000 || !n.toString().equals(text)) {
            return text;
        }
        if (n >= 100000) {
            return (n / 1000).format("%d") + "k";   // "123k", not "123.5k"
        }
        return (n / 1000.0).format("%.1f") + "k";
    }

    function readFull(id as Lang.Number) as Lang.Array {
        var white = Graphics.COLOR_WHITE;
        var info  = ActivityMonitor.getInfo();

        if (id == HEART_RATE) {
            return [fmt(heartRate()), "BPM", white];
        }
        if (id == STEPS) {
            return [fmt(info.steps), "STEPS", white];
        }
        if (id == BATTERY) {
            var battery = System.getSystemStats().battery;
            return [battery.format("%d") + "%", "BATT",
                    (battery <= 15) ? LOW_BATTERY : white];
        }
        if (id == BODY_BATTERY) {
            return [fmt(latest(:getBodyBatteryHistory)), "BODY", white];
        }
        if (id == STRESS) {
            var stress = (info has :stressScore) ? info.stressScore : null;
            if (stress == null) {
                stress = latest(:getStressHistory);
            }
            return [fmt(stress), "STRS", white];
        }
        if (id == CALORIES) {
            return [fmt(info.calories), "KCAL", white];
        }
        if (id == FLOORS) {
            return [fmt((info has :floorsClimbed) ? info.floorsClimbed : null),
                    "FLRS", white];
        }
        if (id == INTENSITY) {
            // Intensity minutes are a weekly goal on Garmin watches.
            var week = (info has :activeMinutesWeek) ? info.activeMinutesWeek : null;
            return [fmt((week == null) ? null : week.total), "INTNS", white];
        }
        return ["--", "", white];
    }

    function fmt(value) as Lang.String {
        return (value == null) ? "--" : value.toNumber().format("%d");
    }

    // Live heart rate, else the most recent sample from the daily history.
    function heartRate() {
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
            // Heart-rate history unavailable on this device.
        }
        return null;
    }

    // Most recent valid (0-100) sample from a SensorHistory series, or null.
    // Looks back a few samples: the newest slot is often null between
    // readings or while the watch is off-wrist.
    function latest(method as Lang.Symbol) {
        if (!(Toybox has :SensorHistory) || !(SensorHistory has method)) {
            return null;
        }
        try {
            var opts = { :period => 10, :order => SensorHistory.ORDER_NEWEST_FIRST };
            var iter = (method == :getBodyBatteryHistory)
                ? SensorHistory.getBodyBatteryHistory(opts)
                : SensorHistory.getStressHistory(opts);
            for (var sample = iter.next(); sample != null; sample = iter.next()) {
                var d = sample.data;
                if (d != null && d >= 0 && d <= 100) {
                    return d;
                }
            }
            return null;
        } catch (e) {
            return null;
        }
    }
}
