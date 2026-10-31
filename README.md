# OpenSnick 🔊 ✨

> An open-source, native macOS menu bar app that turns every scroll into a satisfying tactile experience.  
> Directly inspired by and fully compatible with [trysnick.xyz](https://trysnick.xyz/), with all 7 original mechanical detent voices extracted directly from the website.

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B%20Sonoma%20%2F%20Sequoia-blue?logo=apple)](https://www.apple.com/macos/)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 💡 What is OpenSnick?

OpenSnick is a lightweight macOS utility that lives quietly in your menu bar. As you scroll anywhere on your Mac—in Safari, Chrome, Finder, Slack, or Xcode—it plays micro-acoustic mechanical detent clicks and triggers real Force Touch trackpad haptics in exact lockstep with your fingers.

Instead of paying for commercial proprietary apps, OpenSnick is **100% free, open-source, and offline**.

---

## ✨ Features

- **All 7 Original Voices Extracted from `trysnick.xyz`**:
  - 🟣 **Nok** (`#6366f1`): Crisp detent (Default)
  - 🟣 **Vyl** (`#a855f7`): Vinyl tick
  - 🟢 **Glu** (`#14b8a6`): Gluey pop
  - 🟠 **Dib** (`#f97316`): Tight blip
  - 🔵 **Plo** (`#3b82f6`): Low plop
  - 🩵 **Tok** (`#2dd4bf`): Wooden tok
  - 🔴 **Rub** (`#ef4444`): Rubber snap
- **Force Touch Trackpad Haptics**: Sends real physical detent impulses through your Apple trackpad via `NSHapticFeedbackManager`.
- **Velocity-Aware Audio Engine**: Dynamically measures scroll speed. Slow scrolls whisper gently with fine control; fast flings snap with crisp authority.
- **Zero-Latency Audio Pipeline**: Keeps a pre-warmed pool of low-latency players in memory. Even rapid flings at 120Hz ProMotion never lag or drop clicks.
- **Stepped Mouse Wheel Support**: Immediate tactile clicks on every discrete notch of external mice (Logitech, Razer, USB mice).
- **Momentum Coasting Control**: Toggle whether clicks continue during inertial fling coasting or only while your fingers are actively on the trackpad.
- **Native macOS Menu Bar Interface**: Beautiful popover UI built with SwiftUI and AppKit with volume slider, spacing tuning, live test area, and status indicator.
- **Launch at Login**: Modern `SMAppService` integration for automatic startup without background agent bloat.
- **Offline & Private**: Never connects to the network. Requires no account and sends zero telemetry.
- **Web Companion Demo**: Includes a browser-based web simulator (`Web/index.html`) using HTML5 and the Web Audio API.

---

## 🛠️ Architecture & How It Works

### 1. Scroll Detent Algorithm
The algorithm accurately maps continuous pixel deltas from macOS trackpads to physical detent notches:

$$\text{velocity} = \frac{|\Delta y|}{\max(1, \Delta t)}$$
$$\text{gain} = \min(1.0, 0.25 + \text{velocity} \times 0.18) \times \text{volume}$$

When accumulated scroll distance passes `notchSpacing` (default: 30px) and at least `rateLimitMs` (default: 18ms) has elapsed:
1. `accumulatedDelta` resets modulo `notchSpacing`.
2. The preloaded audio buffer plays with the velocity-scaled gain.
3. The Force Touch trackpad solenoid is pulsed with `.generic` haptic feedback.

### 2. Global Event Interception
macOS restricts global event listening for security. OpenSnick uses `NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel)` combined with `NSEvent.addLocalMonitorForEvents` and a `CGEventTap` listener.
- When Accessibility permission is granted in **System Settings → Privacy & Security → Accessibility**, OpenSnick intercepts scroll deltas system-wide.
- If permission has not been granted yet, a friendly banner in the menu bar popover guides you with a single-click shortcut to System Settings.

---

## 🚀 Quick Start

### Option A: Build and Run with 1 Command
To compile the standalone macOS application bundle:
```bash
./build.sh
open Snick.app
```

### Option B: Install into Applications
To build and install `Snick.app` into `/Applications` (or `~/Applications`):
```bash
./install.sh
```

### Option C: Run via Swift Package Manager
```bash
swift run Snick
```

---

## ⚙️ Granting Accessibility Permission

1. Launch `Snick.app`.
2. Click the Snick waveform icon in your menu bar.
3. If accessibility is needed, click **"Grant Permission"** or **"Open Settings"**.
4. In macOS **System Settings → Privacy & Security → Accessibility**, toggle **Snick** to **ON**.
5. The status badge in Snick will immediately turn green (**Active**), and every scroll will now click!

> **Tip:** You can **Option-Click** the menu bar icon anytime to instantly toggle Snick On/Off!

---

## 🌐 Web Demo / Simulator

You can test the exact sounds and scroll detents in any web browser without compiling:

```bash
cd Web
python3 -m http.server 8000
```
Then visit `http://localhost:8000`.

---

## 📁 Repository Structure

```
.
├── Package.swift               # Swift Package Manager definition
├── build.sh                    # Compiles release binary and packages Snick.app
├── install.sh                  # Installs Snick.app to /Applications
├── README.md                   # Documentation
├── LICENSE                     # MIT License
├── Sources/
│   └── Snick/
│       ├── App/                # App entry point, delegate, status item controller
│       ├── Core/               # Audio engine, haptics, scroll monitoring & processing
│       ├── Models/             # Settings, sound catalog & voice definitions
│       └── UI/                 # SwiftUI popover, voice selector, test scroll area
├── Resources/
│   ├── AppIcon.icns            # Generated high-resolution macOS application icon
│   ├── MenuBarIcon*.png        # Adaptive template icon for menu bar
│   ├── Info.plist              # macOS application metadata (LSUIElement = true)
│   └── Sounds/                 # All 7 extracted WAV files (nok, vyl, glu, dib, plo, tok, rub)
└── Web/                        # Interactive web companion demo
    ├── index.html
    ├── style.css
    ├── app.js
    └── sounds/
```

---

## 📄 License

OpenSnick is licensed under the **[MIT License](LICENSE)**. Free for personal, academic, and commercial use.
Original audio design inspiration credit goes to [trysnick.xyz](https://trysnick.xyz/).
