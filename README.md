# Dota2 Ultrawide Resolution Switcher

A tiny Windows tool to **instantly switch between 5120x1440 and 2560x1440** for **Dota 2** on ultrawide monitors — with one double-click.

---

## 🎮 Why This Tool Exists

I use a **5120x1440 ultrawide monitor**, but for **Dota 2**, I still prefer **2560x1440**:
- The minimap feels more focused
- The UI looks better
- Performance is often more stable

But every time I wanted to play, I had to:
right-click → display settings → scroll → click → click → click…

So I made this.  
Because I’m lazy — and gamers should be too.

This tool lets you:
- Use **5120x1440** for desktop/work
- Double-click to switch to **2560x1440** before Dota 2
- Double-click again to switch back after gaming

No menus. No setup every time. Just one click.

🎥 Short demo:  
https://www.youtube.com/shorts/znN8-oXJh4I

---

## ⚡ Quick Start (For Gamers)

1. Download **`Dota2ResolutionSwitcher.exe`** from the Releases page
2. Put it anywhere (Desktop, Downloads, etc.)
3. **Double-click it once** → first run does a simple setup
4. A desktop shortcut **“Dota2 Resolution Switcher”** will be created
5. From now on, just double-click the shortcut to toggle resolution

That’s it.  
No scripts. No folders. One file.

---

## ⭐ How to Use

- Double-click → switches:
  - **5120x1440 → 2560x1440**
  - or **2560x1440 → 5120x1440**
- The app runs silently and exits.
- Use it before and after launching Dota 2.

👉 Tip: Keep the shortcut on your desktop for fast access.

---

## ✨ Features

- ✅ One-click toggle between **5120x1440 ↔ 2560x1440**
- 🎮 Designed for **Dota 2** ultrawide players
- 🔇 Silent — no console windows
- 🖥️ Portable — single EXE, no install
- 📦 **Zero dependencies** — no NirCmd, nothing to download
- 🔍 **Works at any display scaling** (100% / 125% / 150%)
- 🔄 **Keeps your refresh rate** when switching
- ⭐ Auto creates desktop shortcut on first run

---

## 🖥️ Requirements

- Windows 10 / 11
- Primary monitor supports **5120x1440** and **2560x1440**

---

## 🛠️ Troubleshooting

- ❗ **"It switches one way but won't switch back"** — fixed in **v2.0**.
  If you are on v1.x, upgrade. See the changelog below for what was wrong.
- ❗ If switching fails:  
  Right-click the EXE → **Run as Administrator**
- ❗ On work/school PCs:  
  Security policies may block downloads or shortcuts.
- ❗ Multi-monitor setups:  
  Tool targets the **primary display**.

---

## 🗑️ Uninstall

1. Delete `Dota2ResolutionSwitcher.exe`
2. Delete the desktop shortcut
3. (Optional) Delete folder:  
   `%LOCALAPPDATA%\Dota2ResolutionSwitcher`

Nothing else is left behind.

---

## ⚙️ How It Works (Brief)

On first run:
- Creates a desktop shortcut

On every run:
- Reads the current mode with `EnumDisplaySettings`
- Applies the other mode with `ChangeDisplaySettings`
- Exits immediately

No background process, no downloads, no external tools.

Two details worth knowing:
- The current refresh rate is **kept** across the switch when the target
  resolution supports it, otherwise the highest available rate is used.
- The new mode is validated with `CDS_TEST` before it is applied, so an
  unsupported mode aborts cleanly instead of blanking your screen.

---

## 🖱️ Bonus: `SetRefreshRate.ps1`

A driver update will happily reset your refresh rate to 60Hz and never mention
it. On a 165Hz panel that costs you far more than the resolution does.

```powershell
.\SetRefreshRate.ps1 -List      # what this resolution supports
.\SetRefreshRate.ps1 -Hz 165    # apply it, and persist it across reboots
```

---

## 🙏 Credits

- EXE packaging via **PS2EXE**

As of v2.0 **NirCmd is no longer used or required** — resolution switching is
done through the Win32 display API directly.

---

## 📜 License

This project’s scripts are released under the **MIT License**.  
See `LICENSE` for details.

---

## 👤 Author

Created by **Bruce from Malaysia**  
GitHub: https://github.com/invabun

If this helps you, feel free to star the repo or share it with other ultrawide Dota players.

---

## 📝 Changelog

### v2.0
**Fixes the "switches one way but never switches back" bug.**

v1.x read the current resolution with `System.Windows.Forms.Screen.Bounds`,
which returns **DPI-scaled logical pixels**, not real ones. With Windows
display scaling at 125%, a real 5120x1440 desktop reports as **4096x1152** —
so neither branch of the toggle ever matched and every run fell through to the
`2560x1440` default:

| Actual | v1.x saw | v1.x switched to | Result |
|---|---|---|---|
| 5120x1440 | 4096x1152 | 2560x1440 | worked, looked fine |
| 2560x1440 | 2048x1152 | 2560x1440 | **set to what it already was — nothing happened** |

Scaling is commonly reset to 125% by a GPU driver update, which is why this
tends to break suddenly on a setup that worked for months.

- Resolution is now read and written with `EnumDisplaySettings` /
  `ChangeDisplaySettings`, which are unaffected by DPI scaling
- **NirCmd dependency removed entirely**
- New mode is validated with `CDS_TEST` before being applied
- Changes persist via `CDS_UPDATEREGISTRY` (v1.x changes were lost on reboot)
- Current refresh rate is preserved across the switch
- Clear message when a resolution simply is not available, instead of a
  silent no-op
- Added `SetRefreshRate.ps1`

### v1.0
- First release
- Single portable EXE
- One-click toggle between 5120x1440 and 2560x1440
- Silent operation
- Auto desktop shortcut
