using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

// Garmin Connect cannot edit a side-loaded app's properties, so this menu is
// the editor.

// Accent colours offered on the watch, in the same order and with the same
// values as resources/settings/settings.xml.
module RidgelineColors {
    function values() as Lang.Array<Lang.Number> {
        return [0xFF5500, 0xFF0000, 0x00AA55, 0x00AAFF, 0xFFAA00, 0xFFFFFF];
    }

    function names() as Lang.Array<Lang.ResourceId> {
        return [
            Rez.Strings.ColorOrange, Rez.Strings.ColorRed, Rez.Strings.ColorGreen,
            Rez.Strings.ColorBlue, Rez.Strings.ColorYellow, Rez.Strings.ColorWhite
        ];
    }

    // Name of a colour value, or null if it is not one of the listed ones.
    function nameOf(color) {
        var vals = values();
        for (var i = 0; i < vals.size(); i++) {
            if (vals[i] == color) {
                return names()[i];
            }
        }
        return null;
    }
}

function ridgelineSetProperty(key, value) {
    Application.Properties.setValue(key, value);
    // Same path as a Garmin Connect change: reload into the view and redraw.
    Application.getApp().onSettingsChanged();
}

function ridgelineGetProperty(key, fallback) {
    var value = null;
    try {
        value = Application.Properties.getValue(key);
    } catch (e) {
        value = null;
    }
    return (value == null) ? fallback : value;
}

class RidgelineSettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.AppName });

        var accent = ridgelineGetProperty("AccentColor", 0xFF5500);
        Menu2.addItem(new WatchUi.MenuItem(
            Rez.Strings.AccentColorTitle, RidgelineColors.nameOf(accent),
            :accent, null));

        Menu2.addItem(new WatchUi.ToggleMenuItem(
            Rez.Strings.ShowSecondsTitle, null, :seconds,
            ridgelineGetProperty("ShowSeconds", true) == true, null));

        Menu2.addItem(new WatchUi.ToggleMenuItem(
            Rez.Strings.ShowGoalRingTitle, null, :ring,
            ridgelineGetProperty("ShowGoalRing", true) == true, null));
    }
}

class RidgelineSettingsDelegate extends WatchUi.Menu2InputDelegate {

    hidden var mMenu;

    function initialize(menu) {
        Menu2InputDelegate.initialize();
        mMenu = menu;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :seconds) {
            ridgelineSetProperty("ShowSeconds", (item as WatchUi.ToggleMenuItem).isEnabled());
        } else if (id == :ring) {
            ridgelineSetProperty("ShowGoalRing", (item as WatchUi.ToggleMenuItem).isEnabled());
        } else if (id == :accent) {
            var picker = new RidgelineColorMenu();
            WatchUi.pushView(picker, new RidgelineColorDelegate(mMenu, item), WatchUi.SLIDE_LEFT);
        }
    }
}

class RidgelineColorMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.AccentColorTitle });

        var vals  = RidgelineColors.values();
        var names = RidgelineColors.names();
        for (var i = 0; i < vals.size(); i++) {
            Menu2.addItem(new WatchUi.MenuItem(names[i], null, vals[i], null));
        }

        var current = ridgelineGetProperty("AccentColor", 0xFF5500);
        for (var i = 0; i < vals.size(); i++) {
            if (vals[i] == current) {
                Menu2.setFocus(i);
            }
        }
    }
}

class RidgelineColorDelegate extends WatchUi.Menu2InputDelegate {

    // The parent menu and its "Accent colour" row. setSubLabel alone leaves
    // the native row stale; updateItem pushes the new name to it.
    hidden var mParentMenu;
    hidden var mParentItem;

    function initialize(parentMenu, parentItem) {
        Menu2InputDelegate.initialize();
        mParentMenu = parentMenu;
        mParentItem = parentItem;
    }

    function onSelect(item) {
        var color = item.getId() as Lang.Number;
        ridgelineSetProperty("AccentColor", color);
        mParentItem.setSubLabel(RidgelineColors.nameOf(color));
        var index = mParentMenu.findItemById(mParentItem.getId());
        if (index >= 0) {
            mParentMenu.updateItem(mParentItem, index);
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
