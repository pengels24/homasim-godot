import os

changelog_path = r"d:\game-dev\homasim-godot\changelog\gd-0.1.56.md"
new_content = """
## Translation & Bugfixes (Current Session)
- **UI & Tooltips:** Added translations for guest needs in PIP monitors, CustomTooltips ("Anwesende Mitarbeiter").
- **POI/Rooms:** Fixed hardcoded "Gast" and "Wartet" strings in Lobby and Bar.
- **Conference Room:** Fixed fallback "Gast" string to use proper translation key.
- **Bugfix (Kitchen):** Fixed a bug in `KitchenSmall.gd` where guest names for cooking orders were always displayed as "Gast" because of an invalid property access. Kitchen Live Monitor now correctly shows the guest's name.
- **Build Mode / Demolish:** Converted hardcoded German confirm dialogs and toasts for room demolition into proper translation keys in `DemolishCursor.gd` and added them to `language.csv`.
- **Build Mode / Plots:** Validated that the Plot Purchase UI and dialogs are fully utilizing the translation system.
"""

with open(changelog_path, 'a', encoding='utf-8') as f:
    f.write(new_content)

print("Changelog updated.")
