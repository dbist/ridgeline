using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Complications;

class RidgelineApp extends Application.AppBase {

    hidden var mView;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        mView = new RidgelineView();
        if (WatchUi has :WatchFaceDelegate) {
            return [ mView, new RidgelineDelegate(mView) ];
        }
        return [ mView ];
    }

    // On-watch settings: long-press the watch face (or Settings > Watch
    // Face) and pick Ridgeline's settings. See RidgelineSettings.mc.
    function getSettingsView() {
        var menu = new RidgelineSettingsMenu();
        return [ menu, new RidgelineSettingsDelegate(menu) ];
    }

    // Called when settings change, from Garmin Connect or the on-watch menu.
    function onSettingsChanged() {
        if (mView != null) {
            mView.loadSettings();
        }
        WatchUi.requestUpdate();
    }
}

// Tap a metric column to open its native widget (issue #21).
class RidgelineDelegate extends WatchUi.WatchFaceDelegate {

    hidden var mView;

    function initialize(view) {
        WatchFaceDelegate.initialize();
        mView = view;
    }

    function onPress(clickEvent) {
        if (!(Toybox has :Complications) || !(Complications has :exitTo)) {
            return false;
        }
        var xy = clickEvent.getCoordinates();
        var type = mView.complicationAt(xy[0], xy[1]);
        if (type == null) {
            return false;
        }
        try {
            Complications.exitTo(new Complications.Id(type));
            return true;
        } catch (e) {
            // No such complication on this watch; ignore the tap.
            return false;
        }
    }
}
