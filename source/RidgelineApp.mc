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
