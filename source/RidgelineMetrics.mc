using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Weather;

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
    // Enduro 3 data (issue #19).
    const SOLAR        = 8;
    const BATTERY_DAYS = 9;
    const SUN_EVENT    = 10;
    const ALTITUDE     = 11;
    const LAST_ID      = ALTITUDE;

    const SOLAR_COLOR  = 0xFFAA00;

    const COLUMN_KEYS     = ["LeftMetric", "MiddleMetric", "RightMetric"];
    const COLUMN_DEFAULTS = [HEART_RATE, STEPS, BATTERY];

    const LOW_BATTERY = 0xFF0000;

    // Picker order: what the menu lists, top to bottom.
    function ids() as Lang.Array<Lang.Number> {
        return [HEART_RATE, STEPS, BATTERY, BODY_BATTERY, STRESS, CALORIES,
                FLOORS, INTENSITY, SOLAR, BATTERY_DAYS, SUN_EVENT, ALTITUDE];
    }

    function names() as Lang.Array<Lang.ResourceId> {
        return [
            Rez.Strings.MetricHeartRate, Rez.Strings.MetricSteps,
            Rez.Strings.MetricBattery, Rez.Strings.MetricBodyBattery,
            Rez.Strings.MetricStress, Rez.Strings.MetricCalories,
            Rez.Strings.MetricFloors, Rez.Strings.MetricIntensity,
            Rez.Strings.MetricSolar, Rez.Strings.MetricBatteryDays,
            Rez.Strings.MetricSunEvent, Rez.Strings.MetricAltitude
        ];
    }

    function columnTitles() as Lang.Array<Lang.ResourceId> {
        return [Rez.Strings.LeftMetricTitle, Rez.Strings.MiddleMetricTitle,
                Rez.Strings.RightMetricTitle];
    }

    function isValid(id) as Lang.Boolean {
        return (id instanceof Lang.Number) && id >= 0 && id <= LAST_ID;
    }

    // Labels are at most five characters. At the label row the screen is
    // ~176px wide inside the ring, which fits three five-letter FONT_XTINY
    // labels but not three six-letter ones (FLOORS/INTENS/STRESS collided).
    // The view separately nudges an outer column inward if a wide value
    // would reach the ring.
    //
    // Returns [valueText, label, colour, compactText] for one metric. A value
    // the watch can't supply right now reads "--" rather than hiding the
    // column. compactText is the same value as "12.3k" when it is 10,000 or
    // more (else equal to valueText), for when the row runs out of room.
    function read(id as Lang.Number) as Lang.Array {
        var m = readFull(id);
        return [m[0], m[1], m[2], compact(m[0])];
    }

    // "12345" -> "12.3k"; anything shorter, or not a plain number, unchanged.
    function compact(text as Lang.String) as Lang.String {
        var n = text.toNumber();
        if (n == null || n < 10000 || !n.toString().equals(text)) {
            return text;
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
        if (id == SOLAR) {
            // Solar input now, 0-100 %. Gold so it reads as sunlight.
            var stats = System.getSystemStats();
            var sun = (stats has :solarIntensity) ? stats.solarIntensity : null;
            if (sun != null && sun < 0) { sun = null; }
            return [(sun == null) ? "--" : sun.format("%d") + "%", "SOLAR", SOLAR_COLOR];
        }
        if (id == BATTERY_DAYS) {
            var stats = System.getSystemStats();
            var days = (stats has :batteryInDays) ? stats.batteryInDays : null;
            return [fmt(days), "DAYS", white];
        }
        if (id == SUN_EVENT) {
            return sunEvent();
        }
        if (id == ALTITUDE) {
            return [fmt(altitude()), "ALT", white];
        }
        return ["--", "", white];
    }

    // Next sunrise or sunset, whichever comes first: ["6:58", "RISE", white]
    // or ["16:41", "SET", white]. Needs a location, from the last weather
    // observation or else the last activity fix; "--" without one.
    function sunEvent() as Lang.Array {
        var white = Graphics.COLOR_WHITE;
        var none  = ["--", "RISE", white];
        if (!(Toybox has :Weather) || !(Weather has :getSunrise)) {
            return none;
        }
        var loc = location();
        if (loc == null) {
            return none;
        }

        var now   = Time.now();
        var today = Time.today();
        var rise  = Weather.getSunrise(loc, today);
        var set   = Weather.getSunset(loc, today);
        if (rise != null && now.lessThan(rise)) {
            return [clock(rise), "RISE", white];
        }
        if (set != null && now.lessThan(set)) {
            return [clock(set), "SET", white];
        }
        var tomorrow = today.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
        rise = Weather.getSunrise(loc, tomorrow);
        return (rise == null) ? none : [clock(rise), "RISE", white];
    }

    function location() {
        if (Toybox has :Weather) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.observationLocationPosition != null) {
                return cond.observationLocationPosition;
            }
        }
        var activity = Activity.getActivityInfo();
        return (activity == null) ? null : activity.currentLocation;
    }

    // "16:41" in 24-hour mode, "4:41" in 12-hour mode (no AM/PM: RISE and
    // SET already say which half of the day it is).
    function clock(moment as Time.Moment) as Lang.String {
        var t = Gregorian.info(moment, Time.FORMAT_SHORT);
        var hour = t.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }
        return hour.format("%d") + ":" + t.min.format("%02d");
    }

    // Altitude in the watch's elevation units: metres, or feet for statute.
    function altitude() {
        var metres = null;
        var activity = Activity.getActivityInfo();
        if (activity != null && activity.altitude != null) {
            metres = activity.altitude;
        } else if ((Toybox has :SensorHistory) && (SensorHistory has :getElevationHistory)) {
            try {
                var iter = SensorHistory.getElevationHistory(
                    { :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST });
                var sample = (iter == null) ? null : iter.next();
                metres = (sample == null) ? null : sample.data;
            } catch (e) {
                metres = null;
            }
        }
        if (metres == null) {
            return null;
        }
        if (System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE) {
            return metres * 3.28084;
        }
        return metres;
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

    // Newest sample from a SensorHistory series (needs the SensorHistory
    // permission in manifest.xml), or null if there is none.
    function latest(method as Lang.Symbol) {
        if (!(Toybox has :SensorHistory) || !(SensorHistory has method)) {
            return null;
        }
        try {
            var opts = { :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST };
            var iter = (method == :getBodyBatteryHistory)
                ? SensorHistory.getBodyBatteryHistory(opts)
                : SensorHistory.getStressHistory(opts);
            var sample = (iter == null) ? null : iter.next();
            return (sample == null) ? null : sample.data;
        } catch (e) {
            return null;
        }
    }
}
