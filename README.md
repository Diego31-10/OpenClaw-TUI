<div align="center">

```
                ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗ ██╗    ██╗
              ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗██║    ██║
              ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║██║ █╗ ██║
              ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║██║███╗██║
              ╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║╚███╔███╔╝
               ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝
```

**A sleek, keyboard-driven Terminal User Interface for managing the OpenClaw AI gateway on Windows.**

![Platform](https://img.shields.io/badge/platform-Windows-blue?style=flat-square&logo=windows)
![Shell](https://img.shields.io/badge/shell-Batch%20Script-important?style=flat-square&logo=windows-terminal)
![Version](https://img.shields.io/badge/version-v8-red?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

</div>

---

## 📖 Overview

**OpenClaw-TUI** is a fully self-contained Windows Batch Script that wraps the `openclaw` CLI into a polished, ANSI-colored Text User Interface (TUI). It lets you control every aspect of the OpenClaw AI gateway — start/stop the server, manage AI model tokens, browse the skills marketplace, open the web dashboard, and run diagnostics — all from a single terminal window without memorising any CLI flags.

> Built for power users and AI enthusiasts who want a fast, no-dependency control panel for their local OpenClaw stack.

---

## ✨ Features

| Module | Capabilities |
|---|---|
| 🔌 **Gateway Control** | Start, Stop, Restart the OpenClaw gateway · View live logs |
| 🧠 **Neural Manager** | Check AI model status · Securely paste Anthropic API tokens (hidden input) |
| 🧩 **Skills Modules** | Search the ClawHub marketplace · Batch-update all installed skills |
| 🌐 **Web Dashboard** | One-key launch of the local web UI at `http://127.0.0.1:18789` |
| 🩺 **Support & Doctor** | Full environment diagnostics · Guided onboarding wizard |

**Interface highlights:**
- 🎨 Full ANSI colour support via Virtual Terminal (auto-enabled on launch)
- ⌨️  Single-key navigation throughout every screen
- 🔄 Animated spinner on the main menu to show gateway polling activity
- 📐 Auto-adaptive console size (80×28 / 100×34 / 120×38) based on your terminal's aspect ratio
- 🟢 Live gateway status badge (`ONLINE` / `OFFLINE`) refreshed every loop tick
- 🔒 Hidden token input to keep your Anthropic API key out of your screen recording

---

## 🖥️ Demo

```
  ██████╗ ██████╗ ...  (ASCII banner)

  ┌─ NODE ─ USER@PC   GATEWAY ─ ● ONLINE   TIME ─ 14:32:07 ─┐

  ┌───────────────────────────┐  ┌───────────────────────────┐
  │  [1]  GATEWAY CONTROL     │  │  [4]  WEB DASHBOARD       │
  │       Start · Stop · ...  │  │       Localhost :18789     │
  ├───────────────────────────┤  ├───────────────────────────┤
  │  [2]  NEURAL MANAGER      │  │  [5]  SUPPORT & DOCTOR    │
  │       Auth · Tokens · ... │  │       Onboarding · Diag.  │
  ├───────────────────────────┤  ├───────────────────────────┤
  │  [3]  SKILLS MODULES      │  │  [6]  EXIT                │
  │       ClawHub · Market.   │  │       Close terminal       │
  └───────────────────────────┘  └───────────────────────────┘

    Press 1-6 to navigate  ·  [|]
```

---

## 🚀 Quick Start

### Prerequisites

| Requirement | Notes |
|---|---|
| **Windows 10 / 11** | Virtual Terminal (ANSI) support required |
| **`openclaw` CLI** | Must be available on your `PATH` (install the OpenClaw gateway package first) |
| **`clawdhub` CLI** | Required for Skills → Search functionality |
| **PowerShell** | Used internally to launch the gateway as a background process |

### Installation

```batch
:: 1. Clone or download this repository
git clone https://github.com/Diego31-10/OpenClaw-TUI.git

:: 2. Navigate to the directory
cd OpenClaw-TUI

:: 3. Run the TUI (no install step required)
OpenClaw.bat
```

> **Tip:** Pin `OpenClaw.bat` to your taskbar or create a desktop shortcut for one-click access.

---

## 📋 Usage

Launch the script and use the **number keys** (`1`–`6`) to navigate between modules. Press `V` on any sub-menu to return to the main menu.

### [1] Gateway Control

Controls the OpenClaw gateway service running on port **18789**.

| Key | Action |
|---|---|
| `1` | Start gateway (background process via PowerShell) |
| `2` | Stop gateway (terminates PID + frees port 18789) |
| `3` | Restart gateway |
| `4` | View last 30 log lines |
| `V` | Back to main menu |

The gateway PID is persisted in `%TEMP%\openclaw_gw.pid` and logs are streamed to `%TEMP%\openclaw_gw.log`.

### [2] Neural Manager

Manage the AI model layer powered by Anthropic's Claude.

| Key | Action |
|---|---|
| `S` | Query model status (`openclaw models status`) |
| `T` | Securely paste an Anthropic API token (input is hidden from the terminal) |
| `V` | Back to main menu |

### [3] Skills Modules

Interact with the ClawHub skills ecosystem.

| Key | Action |
|---|---|
| `B` | Search for a skill by name on ClawHub (`clawdhub search <name>`) |
| `U` | Update all installed skills (`openclaw skills update`) |
| `V` | Back to main menu |

### [4] Web Dashboard

Opens `http://127.0.0.1:18789/` in your default browser — no configuration needed.

### [5] Support & Doctor

| Key | Action |
|---|---|
| `D` | Run full environment diagnostic (`openclaw doctor --non-interactive`) |
| `O` | Launch the interactive onboarding setup wizard (`openclaw onboard`) |
| `V` | Back to main menu |

### [6] Exit

Gracefully closes the TUI and restores the cursor.

---

## 🏗️ Architecture

```
OpenClaw.bat
├── Console setup      — chcp 437, ANSI enable, adaptive sizing
├── :menu              — Main loop with spinner, gateway status poll
├── :m_gateway         — Gateway Control sub-menu
│   ├── :gw_start      — PowerShell background launcher
│   ├── :gw_stop       — PID-based process termination
│   ├── :gw_restart    — Stop + Start sequence
│   └── :gw_logs       — Tail last 30 lines from log file
├── :m_brain           — Neural Manager sub-menu
│   ├── :brain_status  — openclaw models status
│   └── :brain_token   — Hidden token input + auth
├── :m_skills          — Skills Modules sub-menu
│   ├── :skills_update — openclaw skills update
│   └── :skills_search — clawdhub search
├── :m_web             — Opens browser to localhost:18789
├── :m_soporte         — Support & Doctor sub-menu
│   ├── :sop_doctor    — openclaw doctor
│   └── :sop_onboard   — openclaw onboard
├── :m_exit            — Clean exit with farewell message
└── Subroutines
    ├── :check_gw      — PID-file based status check
    ├── :do_gw_start   — PowerShell background process wrapper
    └── :do_gw_stop    — taskkill + port 18789 cleanup
```

---

## ⚙️ Configuration

No configuration files are required. The script auto-detects your terminal dimensions at startup and adjusts the console size accordingly:

| Aspect Ratio | Console Size |
|---|---|
| Narrow (< 2.0) | 80 columns × 28 lines |
| Standard | 100 columns × 34 lines |
| Wide (≥ 3.5) | 120 columns × 38 lines |

**Runtime files** (created automatically in `%TEMP%`):

| File | Purpose |
|---|---|
| `openclaw_gw.pid` | Stores the gateway process PID for status checks and stop/restart |
| `openclaw_gw.log` | Gateway stdout/stderr log (viewable from menu option 4) |

---

## 🛠️ Tech Stack

- **Windows Batch Script** — zero external runtime dependencies
- **ANSI / VT100 escape codes** — colours, cursor control, hidden input
- **PowerShell** — used as a lightweight subprocess launcher for the gateway
- **`choice` built-in** — non-blocking, single-key navigation with timeout
- **`tasklist` / `taskkill` / `netstat`** — process lifecycle management
- **`openclaw` CLI** — the underlying AI gateway engine
- **`clawdhub` CLI** — skills marketplace client

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'feat: add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Please keep pull requests focused on a single concern and test on Windows 10 / 11 before submitting.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ for the OpenClaw community · [Report a Bug](https://github.com/Diego31-10/OpenClaw-TUI/issues) · [Request a Feature](https://github.com/Diego31-10/OpenClaw-TUI/issues)

</div>
