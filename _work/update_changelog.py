import os

changelog_path = r"d:\game-dev\homasim-godot\changelog\gd-0.1.56.md"
content = """
## Translation & UI (Modals F1-F10)
- **Modals Block 1 (Overview & Lists):** Fully translated Hotel Overview, Guest List, and Room List. Used `GameState.T` and proper money/number formatting.
- **Modals Block 2 (Personal & Finanzen):** Replaced hardcoded German strings in Staff Modal (assigning/unassigning workplaces) and Finances Modal (transaction categories and amounts). Toasts for Reception check-in/out outcomes also translated.
- **Modals Block 3 (Meta-Systeme):** Handled Questbook (ranks and requirements), Techtree (tooltip texts and confirms), Tutorials (fallback descriptions), and Settings (keybinding collision warns and screen selectors).
"""

with open(changelog_path, 'a', encoding='utf-8') as f:
    f.write(content)

print("Changelog updated.")
