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
        return ridgelineNameOf(names(), values(), color);
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

// Name for a value from parallel names/values lists, or null if absent.
function ridgelineNameOf(names as Lang.Array<Lang.ResourceId>,
        values as Lang.Array<Lang.Number>, value) {
    for (var i = 0; i < values.size(); i++) {
        if (values[i] == value) {
            return names[i];
        }
    }
    return null;
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

        // One item per metric column (issue #20); ids are the property keys.
        var keys   = RidgelineMetrics.COLUMN_KEYS;
        var titles = RidgelineMetrics.columnTitles();
        for (var i = 0; i < keys.size(); i++) {
            var current = ridgelineGetProperty(keys[i], RidgelineMetrics.COLUMN_DEFAULTS[i]);
            Menu2.addItem(new WatchUi.MenuItem(titles[i],
                ridgelineNameOf(RidgelineMetrics.names(), RidgelineMetrics.ids(), current),
                keys[i], null));
        }
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
            openPicker(item, "AccentColor", Rez.Strings.AccentColorTitle,
                RidgelineColors.names(), RidgelineColors.values(), 0xFF5500);
        } else if (id instanceof Lang.String) {
            // A metric column: the item id is its property key.
            var keys = RidgelineMetrics.COLUMN_KEYS;
            for (var i = 0; i < keys.size(); i++) {
                if (keys[i].equals(id)) {
                    openPicker(item, keys[i], RidgelineMetrics.columnTitles()[i],
                        RidgelineMetrics.names(), RidgelineMetrics.ids(),
                        RidgelineMetrics.COLUMN_DEFAULTS[i]);
                }
            }
        }
    }

    hidden function openPicker(item, key, title, names, values, fallback) {
        var current = ridgelineGetProperty(key, fallback);
        WatchUi.pushView(
            new RidgelinePickerMenu(title, names, values, current),
            new RidgelinePickerDelegate(key, mMenu, item, names, values),
            WatchUi.SLIDE_LEFT);
    }
}

// A one-of-N list (accent colour, metric for a column), focused on the
// current value.
class RidgelinePickerMenu extends WatchUi.Menu2 {

    function initialize(title, names as Lang.Array<Lang.ResourceId>,
            values as Lang.Array<Lang.Number>, current) {
        Menu2.initialize({ :title => title });
        for (var i = 0; i < values.size(); i++) {
            Menu2.addItem(new WatchUi.MenuItem(names[i], null, values[i], null));
            if (values[i] == current) {
                Menu2.setFocus(i);
            }
        }
    }
}

class RidgelinePickerDelegate extends WatchUi.Menu2InputDelegate {

    hidden var mKey;
    // The parent menu and the row that opened this picker. setSubLabel alone
    // leaves the native row stale; updateItem pushes the new name to it.
    hidden var mParentMenu;
    hidden var mParentItem;
    hidden var mNames;
    hidden var mValues;

    function initialize(key, parentMenu, parentItem, names, values) {
        Menu2InputDelegate.initialize();
        mKey = key;
        mParentMenu = parentMenu;
        mParentItem = parentItem;
        mNames = names;
        mValues = values;
    }

    function onSelect(item) {
        var value = item.getId() as Lang.Number;
        ridgelineSetProperty(mKey, value);
        mParentItem.setSubLabel(ridgelineNameOf(mNames, mValues, value));
        var index = mParentMenu.findItemById(mParentItem.getId());
        if (index >= 0) {
            mParentMenu.updateItem(mParentItem, index);
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
