# Display profile (Windows + mobile)

> **Purpose:** One **logical** design resolution (**1080×1920** portrait per `docs/UI_SCREENS.md`) with correct scaling on **desktop** (comfortable window, no stretch distortion) and **native** behavior on **Android / iOS** (no forced window size).
>
> **Implementation:** `scripts/autoload/display_profile.gd` (autoload **DisplayProfile**), ordered **before** `UIManager` in `project.godot`.
>
> **Last updated:** 2026-04-10

---

## Display profile

Weather Whether uses a **single logical** design resolution (**1080×1920** portrait). Desktop builds get a **windowed 9:16** frame via **DisplayProfile**; **mobile** exports use OS fullscreen; **CI** remains headless-safe. Details below: project settings, runtime behavior, simulated presets, and Linear/PM notes.

## Project settings

| Setting | Value | Why |
|--------|--------|-----|
| `display/window/size/viewport_width` | 1080 | Design width |
| `display/window/size/viewport_height` | 1920 | Design height |
| `display/window/stretch/mode` | `canvas_items` | Scale controls |
| `display/window/stretch/aspect` | `keep` | Preserve 9:16; letterbox if the window aspect differs |
| `display/window/handheld/orientation` | `1` (portrait) | Mobile exports default to portrait |

---

## Runtime behavior

- **Android / iOS / Web:** `DisplayProfile` **does nothing** — the OS or browser controls fullscreen / surface size.
- **Desktop (Windows, Linux, macOS) + editor:** On startup, the main window is resized to a **9:16** frame that fits ~92% of the **usable** screen height (capped at 1080×1920), centered. Minimum window size **360×640** (simulated small phone floor).
- **Headless** (`DisplayServer` name `headless`): no resize — keeps CI/GUT stable.

---

## Simulated phone sizes (desktop / editor)

Set environment variable **`WHETHER_DISPLAY_PRESET`** before launching Godot or the exported `.exe`:

| Value | Window size | Use |
|-------|-------------|-----|
| *(unset)* | Auto fit | Default |
| `auto` | Auto fit | Same as default |
| `360` / `sim_360` | 360×640 | Dense-phone check |
| `540` / `sim_540` | 540×960 | Mid |
| `720` / `sim_720` | 720×1280 | Common test |
| `1080` / `native` / `native_design` | 1080×1920 | 1:1 design pixels |

Unknown values log a warning and fall back to **auto**.

**PowerShell (session):**

```powershell
$env:WHETHER_DISPLAY_PRESET = "360"
pwsh ./tools/tasks/launch.ps1
```

**Code (debug / future settings menu):** call `DisplayProfile.apply_preset(DisplayProfile.Preset.SIM_720)` etc.

---

## Layout references

- **Mobile wireframe:** `assets/mocks/level_mockup.svg` (360×640 logical proportions).
- **Desktop gameplay chrome:** `assets/mocks/gameplay_desktop.svg` — use for **where** HUD/queue/hand sit when the window is wide; `keep` stretch still paints the 1080×1920 scene letterboxed inside the portrait window.

---

## Linear / PM

If an issue was opened for “desktop too large” / “simulated mobile,” close it when this autoload and `stretch/aspect=keep` are on `main`. PM seed row: `tools/linear/pm-doc-issue-candidates.ts` → id **`ui-display-profile-desktop-mobile`**.
