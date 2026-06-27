import os

file_path = r'd:\game-dev\homasim-godot\scenes\main_menu\MainMenu.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add DisclaimerModal reference
if '@onready var _disclaimer_modal' not in content:
    content = content.replace(
        '@onready var _dashboard_modal:  Control      = \n',
        '@onready var _dashboard_modal:  Control      = \n@onready var _disclaimer_modal: StandardModal = \n'
    )

# Add disclaimer logic to _ready
old_ready = '''\tif GameState.open_dashboard_next:
\t\tGameState.open_dashboard_next = false
\t\t_on_play_pressed()'''

new_ready = '''\tif GameState.open_dashboard_next:
\t\tGameState.open_dashboard_next = false
\t\t_on_play_pressed()
\telse:
\t\t_check_disclaimer()'''

if '_check_disclaimer()' not in content:
    content = content.replace(old_ready, new_ready)
    
    # Add _check_disclaimer func
    content += '''\n
# =============================================================================
func _check_disclaimer() -> void:
\tvar config = SaveManager.load_global_config()
\tif not config.get("dont_show_disclaimer", false):
\t\t_disclaimer_modal.set_content("res://scenes/main_menu/ModalContentDisclaimer.tscn")
\t\t_disclaimer_modal.open(GameState.T("ui.disclaimer.title"))
'''

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated MainMenu.gd")