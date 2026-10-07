# Liquid Glass Theme Toggle

An Apple Liquid Glass-inspired Rainmeter skin that toggles Windows between Light and Dark mode with a single click or drag.

![Rainmeter 4.5](https://img.shields.io/badge/Rainmeter-4.5-blue)
![Windows 11](https://img.shields.io/badge/Windows-11-0078D4)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Spring-physics animation** — the knob overshoots and settles with a damped spring, giving the toggle a satisfying, physical feel
- **Liquid stretch effect** — the knob stretches in the direction of motion while traveling
- **Progressive disclosure** — a frosted glass lens morphs into view on hover, keeping the idle state minimal
- **Click or drag** — tap to toggle instantly, or drag the knob and release (it snaps to the nearest side with flick momentum)
- **Animated sun & moon icons** — vector-drawn sun (8 rotating rays) and crescent moon (CSG exclude) cross-fade and rotate during the transition
- **Per-monitor wallpaper switching** — automatically sets different wallpapers per monitor using the IDesktopWallpaper COM interface, with landscape/portrait auto-detection
- **Multi-monitor taskbar sync** — directly notifies Shell_TrayWnd and Shell_SecondaryTrayWnd so all taskbars update immediately
- **External sync** — polls the registry so the toggle stays in sync if you change the theme from Windows Settings
- **Race-condition safe** — rapid double-toggles are serialized with a mutex so wallpapers never desync from the theme

## Preview

[> Add a GIF or video of the toggle in action here.](https://drive.google.com/file/d/1VCnLIpqnf9Vz6IWr9cETKOmxp85hSEaw/view)

## Installation

1. Install [Rainmeter 4.5+](https://www.rainmeter.net/)
2. Clone or download this repository into your Rainmeter Skins folder:
   ```
   %USERPROFILE%\Documents\Rainmeter\Skins\LiquidGlassToggle
   ```
3. Add your wallpapers to `@Resources\wallpapers\` and update the filenames in `@Resources\SetTheme.ps1`
4. Open Rainmeter, find **LiquidGlassToggle**, and load `light-dark-mode.ini`

## Customization

| Setting | Location | Description |
|---------|----------|-------------|
| Scale | `[Variables]` → `S` | Overall size multiplier (default `0.3333` = ~77×43 px) |
| Wallpapers | `@Resources\SetTheme.ps1` → `$walls` | Map of light/dark wallpapers per orientation |

## How It Works

The skin is built entirely with Rainmeter's Shape meter (vector graphics) — no image files for the UI. Two `ActionTimer` plugins drive independent spring simulations: one for knob travel, one for the hover glass morph. Drag interaction is handled by 23 invisible strips that report cursor position, working around Rainmeter 4.5's lack of a Mouse plugin.

Theme switching is delegated to a PowerShell script that sets the registry, broadcasts `WM_SETTINGCHANGE` with `ImmersiveColorSet`, and sets per-monitor wallpapers via COM interop — all protected by a named mutex.

## Tech Stack

Rainmeter · PowerShell · C# (COM Interop) · Win32 API · IDesktopWallpaper COM Interface · Claude AI (Pair Programming)

## License

[MIT](LICENSE)
