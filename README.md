# Ridgeline — Garmin Enduro 3 watch face

A high-legibility Monkey C watch face: oversized time, date, step-goal ring,
heart rate / steps / battery row, notification dot. Built for the Enduro 3's
280×280 memory-in-pixel display (black background, no gradients — the things MIP
actually renders well).

See `preview.png` for the layout.

## What you need (one-time, ~20 minutes)

1. **Connect IQ SDK Manager** — https://developer.garmin.com/connect-iq/sdk/
   Sign in with your Garmin account, install the latest SDK, then in the
   *Devices* tab tick **Enduro 3** and download it.
2. **VS Code** + the official **Monkey C** extension (publisher: Garmin).
3. **Developer key** — in VS Code: `Ctrl/Cmd+Shift+P` →
   `Monkey C: Generate a Developer Key`. Point the extension at the SDK when
   prompted.

## Build

1. `File → Open Folder` → this `Ridgeline` folder.
2. `Ctrl/Cmd+Shift+P` → `Monkey C: Build for Device` → choose **Enduro 3** →
   pick an output folder. You get `Ridgeline.prg`.

Optional sanity check first: `Monkey C: Run App` launches the simulator with the
Enduro 3 skin so you can see it before it touches the watch.

If "Enduro 3" doesn't appear in the device list, run
`Monkey C: Edit Products` and add it there — that writes the correct device id
into `manifest.xml` (this file guesses `enduro3`).

## Install on the watch — no app store needed

1. Connect the Enduro 3 by USB. It mounts as a drive.
2. Copy `Ridgeline.prg` into **`GARMIN/APPS/`** on the watch.
3. Safely eject, unplug. The watch re-indexes apps on disconnect.
4. On the watch: hold **UP/MENU** → *Watch Face* → scroll to **Ridgeline** →
   *Apply*.

Side-loading skips Garmin's store review entirely. If you later want it on the
store, that's a separate developer-account submission.

## Settings

Editable from Garmin Connect (Connect IQ → Ridgeline → Settings):

- Accent colour (orange / red / green / blue / yellow / white)
- Seconds on wrist-raise (off saves battery)
- Step-goal ring on/off

Side-loaded app settings occasionally don't sync. If so, just change the
defaults in `resources/properties.xml` and rebuild.

## Files

- `source/RidgelineView.mc` — all the drawing. Layout is in fractions of screen
  height, so tweaks are safe and it scales to other Garmin devices.
- `source/RidgelineApp.mc` — entry point.
- `manifest.xml` — app id, target devices, permissions.
- `resources/` — strings, settings, launcher icon.

## Battery note

Seconds force a 1 Hz redraw while the wrist is raised; `onEnterSleep` drops back
to once-a-minute. This is the normal cost of any seconds-displaying face — turn
seconds off in settings if you want the stock-face battery life back.
