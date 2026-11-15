import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Complications;

class RidgelineApp extends Application.AppBase {

    hidden var mView as RidgelineView or Null = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary or Null) as Void {
    }

    function onStop(state as Dictionary or Null) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new RidgelineView();
        mView = view;
        if (WatchUi has :WatchFaceDelegate) {
            return [ view, new RidgelineDelegate(view) ];
        }
        return [ view ];
    }

    // Reached by holding UP/MENU -> Watch Face -> Ridgeline.
    function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        var menu = new RidgelineSettingsMenu();
        return [ menu, new RidgelineSettingsDelegate(menu) ];
    }

    // Called when settings change, from Garmin Connect or the on-watch menu.
    function onSettingsChanged() as Void {
        var view = mView;
        if (view != null) {
            view.loadSettings();
        }
        WatchUi.requestUpdate();
    }
}

// Touch-and-hold a metric column to open its native widget. onPress is the
// hold; onTap only reaches a watch face in config mode.
class RidgelineDelegate extends WatchUi.WatchFaceDelegate {

    hidden var mView as RidgelineView;

    function initialize(view as RidgelineView) {
        WatchFaceDelegate.initialize();
        mView = view;
    }

    function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
        mView.onPartialBudgetExceeded();
    }

    function onPress(clickEvent as ClickEvent) as Boolean {
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
