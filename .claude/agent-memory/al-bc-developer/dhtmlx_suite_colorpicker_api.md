---
name: dhtmlx-suite-colorpicker-api
description: Verified DHTMLX Suite Colorpicker widget API facts (grepped from suite.js) - used to build the hex-color AssistEdit lookup (page 50709, src/dhx/color_picker)
metadata:
  type: project
---

Added 2026-08-20: `src/dhx/color_picker/` is a new DHTMLX Suite **Colorpicker**
control add-in (`DHXColorPickerAddin`), used as an `OnAssistEdit()` input helper on 5
plain-Text hex-color fields (page 50654's Unassigned Capacity Color / Envelope Color /
Envelope Border Color / Assigned Color, and pageext 50626's Bar Color on "Skill Codes").
This is an INPUT mechanism only - it does not touch codeunit 50609 "Color Constants
Opti." or any color-resolution/rendering code. Same "grep suite.js directly, don't trust
public docs" approach as [[dhtmlx-suite-chart-api]] and [[dhtmlx-suite-grid-api]].

**Verified DHTMLX Suite Colorpicker API** (grepped directly from `src/dhx/suite.js`):
- `dhx.Colorpicker` IS the real top-level exported class (unlike Grid, which is
  actually `ProGrid` wrapping the real `Grid`/`ExtendedGrid` - see
  [[dhtmlx-suite-grid-api]]). Confirmed at two points: the class definition itself
  (`exports.Colorpicker = Colorpicker`, suite.js ~line 35308) and the top-level
  re-export (`Object.defineProperty(exports, "Colorpicker", { get: function () {
  return ts_colorpicker_1.Colorpicker; } })`, ~line 26279). `new dhx.Colorpicker(node,
  config)` behaves exactly like the class shown in source, no wrapper indirection.
- Config defaults (~line 34972-34982): `{ css: "", grayShades: true, pickerOnly:
  false, paletteOnly: false, customColors: [], palette: <built-in swatch set>, width:
  "238px", mode: "palette", transparency: true }`. `mode: "picker"` switches to the
  full hue/saturation/alpha slider view **plus a manual hex text input** (confirmed via
  the `"hex_input"` case in the internal click/input handler, ~line 35098, which writes
  into `_pickerState.customHex`) - this is what the color_picker add-in uses, since this
  app's fields all need arbitrary hex, not just a fixed palette. `transparency: false`
  truncates any 9-char (`#RRGGBBAA`) value down to 6 inside `setValue()` itself
  (~line 35016: `value = !this.config.transparency && value.length === 9 ?
  value.slice(0,-2) : value`) - set this to keep values as plain `#RRGGBB`, matching
  every existing field's documented format.
- **Public methods**: `.setValue(hex)` seeds/sets the picker (fires `beforeChange` then
  `change`+`colorChange` if the color actually changes focus); `.getValue()` returns
  `this._selected || ""`; `.clear()` resets to `""`; `.setCurrentMode("palette"|
  "picker")` toggles the two views at runtime; `.destructor()` tears down (same
  wipe-and-rebuild convention as Chart/Grid is NOT needed here though - this widget is
  only ever constructed once per control-add-in lifetime, seeded via `setValue`, since
  there's no per-record "reload" concept the way a chart/grid has).
- **Events** (`ColorpickerEvents` enum, ~line 12818-12832): `beforeChange` (cancellable
  pre-commit hook, fires with the candidate color BEFORE it's applied - not used here),
  `change` (fires with `[this._selected]` - the real committed value - on every discrete
  pick: a palette swatch click via `_onColorClick`, a committed manual hex-input entry,
  a `clear()` call, or a `setValue()` call that actually moves focus), `colorChange`
  (**deprecated alias**, suite.js's own comment: `// TODO: remove suite_7.0` - fired
  immediately alongside `change` every single time, never independently - do NOT wire
  to this one, it carries no different information and is slated for removal),
  `apply`/`selectClick` (only fire from the picker-mode's explicit "Apply" button - would
  reintroduce a confirm round-trip this feature's spec explicitly avoids), `modeChange`/
  `viewChange` (palette<->picker toggle), `cancelClick`.
- **Chosen wiring**: `picker.events.on("change", function (selectedColor) {
  InvokeExtensibilityMethod("OnColorChanged", [selectedColor]); })` - fires live on
  every real pick, no separate confirm step needed from the widget itself. Dragging the
  hue/alpha range sliders (`_setRangeGrip`) only calls `this.paint()` directly and does
  NOT fire `change` mid-drag - so there is no "intermediate drag state" noise to filter
  out the way a naive slider integration might fear; `change` only fires on discrete
  commit actions.

**How to apply:** If DHTMLX Suite Colorpicker needs a fixed brand-palette mode
elsewhere (e.g. `paletteOnly: true` with `customColors` pre-populated from this app's
own color set), re-check `_onColorClick`'s right-click-to-delete custom-color behavior
(~line 35130, tied to `customColors`) before assuming palette-only mode behaves
identically to the picker-mode path documented above - only the picker-mode path (hex
input + "change" event) has been exercised/verified end-to-end here.
