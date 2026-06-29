import re

with open('d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentFinances.gd', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace hardcoded arrays with translation calls via a _ready() update, or we can just replace them directly.
# Wait, arrays of Translation strings can be defined, but GameState.T() is dynamic.
# So we can't initialize them as constants with GameState.T() because GameState might not be ready yet, or we can just define keys and translate on use.

text = text.replace('const TIME_TEXTS = ["Heute", "Gestern", "Alle"]', 'const TIME_TEXTS = ["finances.time.today", "finances.time.yesterday", "finances.time.all"]')
text = text.replace('const CAT_TEXTS = ["Alle", "Bau & Abriss", "Personal", "Gäste/Gastro", "Quests/Bonus", "Forschung"]', 'const CAT_TEXTS = ["finances.cat.all", "finances.cat.construction", "finances.cat.personal", "finances.cat.gastro", "finances.cat.quest", "finances.cat.research"]')
text = text.replace('const TYPE_TEXTS = ["Alle", "Nur Einnahmen", "Nur Ausgaben"]', 'const TYPE_TEXTS = ["finances.type.all", "finances.type.income", "finances.type.expense"]')

# In _update_list():
text = text.replace('%LblTime.text = TIME_TEXTS[time_idx]', '%LblTime.text = GameState.T(TIME_TEXTS[time_idx])')
text = text.replace('%LblCat.text = CAT_TEXTS[cat_idx]', '%LblCat.text = GameState.T(CAT_TEXTS[cat_idx])')
text = text.replace('%LblType.text = TYPE_TEXTS[type_idx]', '%LblType.text = GameState.T(TYPE_TEXTS[type_idx])')

text = text.replace('%TitleIncome.text = "Einnahmen Heute"', '%TitleIncome.text = GameState.T("finances.title.income.today")')
text = text.replace('%TitleExpense.text = "Ausgaben Heute"', '%TitleExpense.text = GameState.T("finances.title.expense.today")')
text = text.replace('%TitleTotal.text = "Saldo Heute"', '%TitleTotal.text = GameState.T("finances.title.total.today")')

text = text.replace('%TitleIncome.text = "Einnahmen Gestern"', '%TitleIncome.text = GameState.T("finances.title.income.yesterday")')
text = text.replace('%TitleExpense.text = "Ausgaben Gestern"', '%TitleExpense.text = GameState.T("finances.title.expense.yesterday")')
text = text.replace('%TitleTotal.text = "Saldo Gestern"', '%TitleTotal.text = GameState.T("finances.title.total.yesterday")')

text = text.replace('%TitleIncome.text = "Einnahmen Gesamt"', '%TitleIncome.text = GameState.T("finances.title.income.all")')
text = text.replace('%TitleExpense.text = "Ausgaben Gesamt"', '%TitleExpense.text = GameState.T("finances.title.expense.all")')
text = text.replace('%TitleTotal.text = "Gesamtsaldo"', '%TitleTotal.text = GameState.T("finances.title.total.all")')

# Also, wait! In ModalContentFinances.tscn there are hardcoded headers!
# We can translate them in _ready().
ready_patch = """func _ready() -> void:
\t%BtnTimeLeft.pressed.connect(_on_btn_time_left)
"""

new_ready = """func _ready() -> void:
\t$Panel/Margin/VBox/Header/LblDay.text = GameState.T("finances.header.time")
\t$Panel/Margin/VBox/Header/LblCat.text = GameState.T("finances.header.cat")
\t$Panel/Margin/VBox/Header/LblDesc.text = GameState.T("finances.header.desc")
\t$Panel/Margin/VBox/Header/LblAmount.text = GameState.T("finances.header.amount")
\t%BtnTimeLeft.pressed.connect(_on_btn_time_left)
"""
text = text.replace(ready_patch, new_ready)

with open('d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentFinances.gd', 'w', encoding='utf-8') as f:
    f.write(text)


# SimBrowserTile.gd
with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowserTile.gd', 'r', encoding='utf-8') as f:
    tile_gd = f.read()
    
tile_gd = tile_gd.replace('lbl_title.text = data.get("title", "")', 'lbl_title.text = GameState.T(data.get("title", ""))')
tile_gd = tile_gd.replace('lbl_desc.text = data.get("desc", "")', 'lbl_desc.text = GameState.T(data.get("desc", ""))')

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowserTile.gd', 'w', encoding='utf-8') as f:
    f.write(tile_gd)

# SimBrowser.gd
with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowser.gd', 'r', encoding='utf-8') as f:
    sim_gd = f.read()

sim_gd = sim_gd.replace('_show_message("Hallo Peter! Schoen dich hier hinter dem Vorhang zu treffen.")', '_show_message(GameState.T("sim.easter.angelus"))')
sim_gd = sim_gd.replace('_show_message("Ich wusste, dass du hier suchst. Hallo vom anderen Ende der Leitung.")', '_show_message(GameState.T("sim.easter.claude"))')
sim_gd = sim_gd.replace('_show_message("404 - Not Found\\\\n\\\\nDie gewuenschte URL \'%s\' ist derzeit (noch) nicht verfuegbar." % url)', '_show_message(GameState.T("sim.error.404") % url)')

ready_patch_sim = """func _ready() -> void:
\tbtn_close.pressed.connect(close)"""

new_ready_sim = """func _ready() -> void:
\tlbl_tip.text = GameState.T("sim.tip")
\t$Margin/Window/VBox/ContentBg/Margin/Scroll/VBox/HeaderBox/LblSub.text = GameState.T("sim.title.sub")
\tbtn_close.pressed.connect(close)"""
sim_gd = sim_gd.replace(ready_patch_sim, new_ready_sim)

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowser.gd', 'w', encoding='utf-8') as f:
    f.write(sim_gd)

print("GD files updated for translation")
