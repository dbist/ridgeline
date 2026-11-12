using Toybox.Application;
using Toybox.WatchUi;

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

    // Called when the user changes settings in Garmin Connect.
    function onSettingsChanged() {
        if (mView != null) {
            mView.loadSettings();
        }
        WatchUi.requestUpdate();
    }
}

// Hears when always-on seconds exceed the partial-update power budget.
class RidgelineDelegate extends WatchUi.WatchFaceDelegate {

    hidden var mView;

    function initialize(view) {
        WatchFaceDelegate.initialize();
        mView = view;
    }

    function onPowerBudgetExceeded(powerInfo) {
        mView.onPartialBudgetExceeded();
    }
}
