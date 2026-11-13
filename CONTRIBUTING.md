# Contributing to Ridgeline

Issues and pull requests are welcome. If you would rather fork the project and
build your own face from it, that is equally fine — the Apache-2.0 license lets
you do that.

## Getting started

The README already covers one-time SDK setup, building, and installing on the
watch. Before you open a PR, follow those steps from a clean clone and confirm
that `monkeyc` builds the `.prg` successfully.

That needs a Garmin account: the SDK Manager only downloads the SDK and the
Enduro 3 device files after you sign in, and `monkeyc` cannot build for a
device whose files are missing.

## Running the unit tests

The step-ring maths has `(:test)` cases in `source/RidgelineRingTests.mc`.
They run in the simulator, not in CI. With `SDK` set as in the README's
*Build* section:

    "$SDK/bin/connectiq" &                    # start the simulator
    "$SDK/bin/monkeyc" -d enduro3 -f monkey.jungle \
      -y ~/.garmin/developer_key.der -t -o build/RidgelineTest.prg
    "$SDK/bin/monkeydo" build/RidgelineTest.prg enduro3 -t

`(:test)` code is left out of normal builds, so it never ships in the `.prg`.

## What to include in a pull request

1. **It builds.** The PR should leave `monkeyc` able to produce the device
   binary without errors. If you change code that is touched by strict type
   checking, note whether you also ran `monkeyc -l 3` and what it reported.
2. **Say how you checked it.** Watch faces are device-specific because of font
   metrics, layout fractions, and the round screen. Please state which physical
   watch or which simulator device you ran it on.
3. **Layout changes must derive from runtime font metrics.** The current layout
   deliberately avoids hardcoded pixel sizes and instead uses
   `dc.getFontHeight()` and fractions of screen height. Any visual change
   should follow that pattern so it stays correct across devices.
4. **Keep the CLI-first workflow.** The project is intended to build without
   requiring any particular editor, so avoid adding editor-specific files,
   extensions, or project formats unless there is a clear reason to do so.

## Why CI does not build the device binary

The public GitHub Actions workflow (`checks.yml`) checks XML/SVG
well-formedness, guards against accidentally committing keys or build output,
and verifies that relative Markdown links resolve. It needs no secrets. It runs
on pushes to `main` rather than on pull requests, to save Actions minutes, so
run the same checks locally if you want them before review. What it does
**not** do is compile for a watch. Device definitions are a separate, authenticated download
from Garmin, and building for a specific watch requires personal Garmin account
credentials. That decision is recorded in issue #1. For this repository, local
verification is what counts.

## Licensing

By contributing, you agree that your contribution is licensed under the
Apache-2.0 license, the same license that covers the rest of the project.
See [LICENSE](LICENSE) for the full text.
