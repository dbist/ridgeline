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
