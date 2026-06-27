import os

file_path = r'd:\game-dev\homasim-godot\autoload\SettingsManager.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add variable
if 'var dont_show_disclaimer: bool = false' not in content:
    content = content.replace(
        'var language: String = "de"        # "de" / "en" (erweiterbar)',
        'var language: String = "de"        # "de" / "en" (erweiterbar)\nvar dont_show_disclaimer: bool = false'
    )

# Save
if 'cfg.set_value("system", "dont_show_disclaimer", dont_show_disclaimer)' not in content:
    content = content.replace(
        'cfg.set_value("system", "language", language)',
        'cfg.set_value("system", "language", language)\n\tcfg.set_value("system", "dont_show_disclaimer", dont_show_disclaimer)'
    )

# Load
if 'dont_show_disclaimer = cfg.get_value("system", "dont_show_disclaimer", false)' not in content:
    content = content.replace(
        'language             = cfg.get_value("system", "language", "de")',
        'language             = cfg.get_value("system", "language", "de")\n\t\tdont_show_disclaimer = cfg.get_value("system", "dont_show_disclaimer", false)'
    )

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated SettingsManager")