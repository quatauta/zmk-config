# AGENTS.md

ZMK user config: splitkb Kyria rev3, nice!nano v2, BLE split, left = central.
Fork of urob/zmk-config ideas; QWERTY base.

## Commands
- `./build.sh` — Docker build (`zmkfirmware/zmk-build-arm:4.1-branch`, macOS starts OrbStack/Docker) of every `build.yaml` entry → `_firmware/<timestamp>/*.uf2`. Only verification available; run after any `config/` change.
- `./draw.sh` — regenerate `draw/keymap.svg` via keymap-drawer. Needs `./build.sh` run once first (reads `_build/zmk-config/modules/zmk/helpers/include`).
- `./flash.sh _firmware/<timestamp>` — copy uf2 to `/Volumes/NICENA_L|R` (halves must be in bootloader). Hardware action: never run unasked.
- CI: GitHub only (`.github/workflows/build.yml` → ZMK reusable workflow, reads `build.yaml`). Remotes: `origin` GitLab, `github`.

## Layout
- `config/kyria_rev3.keymap` — layers, HRMs, behaviors. Includes `combos.dtsi`, `leader.dtsi`, `mouse.dtsi`.
- `config/kyria_rev3.conf` — Kconfig (sleep, pointing, BLE tweaks; backlight/underglow off).
- `config/west.yml` — all revisions pinned by `pin-west`; update with `pin-west bump`, never hand-edit the "imported projects" block. Zephyr modules limited by `name-allowlist`.
- `build.yaml` — left gets ZMK Studio (`studio-rpc-usb-uart` snippet).
- `draw/config.yaml` — legends for keymap-drawer; `draw/keymap.yaml` only supplies physical layout.
- `_*` dirs gitignored build/cache output.

## Landmines
- Layer index = `ZMK_LAYER` declaration order; `#define DEF..MOUSE` must match it. Always reference layers by name, never by number.
- Key positions use zmk-helpers labels (`LT5`…`RH4`, `LF0/LF1/RF0/RF1` = Kyria extra keys). `KEYS_L/KEYS_R` come from `zmk-helpers/key-labels/kyria.h`; `THUMBS` overridden locally to include LF/RF.
- `combos.dtsi` must be included after the `ZMK_COMBO_8` HRM-combo hack. 8-arg `ZMK_COMBO` = hold-tap combo (tap-only HRM workaround, ZMK #544).
- `leader.dtsi` redefines `ZMK_LEADER_SEQUENCE` to accumulate into one `leader` node.
- `&caps_word` delete-property relies on ZMK PR #1451 (TODO).
- Layer grids: 12/12/16/10 keys per row; keep column alignment (`tw=226`).
- New custom behavior visible in keymap → add legend to `draw/config.yaml` `raw_binding_map`.
- Zephyr bump → change Docker tag in `build.sh` to match.

## Workflow
- Keymap change → `./build.sh` → `./draw.sh` → commit SVG separately (`draw: Regenerate keymap SVG`).
- Commit subject: `<area>: <Imperative>` (`keymap:`, `build:`, `draw:`, `draw.sh:`).
