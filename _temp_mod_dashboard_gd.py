import os

path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.gd'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if 'const NEW_HOTEL_SCENE' in line:
        new_lines.append(line)
        new_lines.append('const HOTEL_CARD_SCENE   := preload("res://scenes/dashboard/DashboardHotelCard.tscn")\n')
        continue
    
    if 'var hotel_container:   VBoxContainer' in line:
        new_lines.append(line.replace('VBoxContainer', 'GridContainer'))
        continue

    if '@onready var btn_new_hotel:     Button    = $MainArea/HotelSection/Header/BtnNewHotel' in line:
        new_lines.append('@onready var btn_new_hotel:     Button    = %BtnNewHotelCard\n')
        continue
    
    if 'btn_new_hotel.text = GameState.T("dashboard.btn.new_hotel")' in line:
        # no longer need to set this here since we set text to ➕ in tscn and the label is separate
        continue
    
    if 'func _load_hotels() -> void:' in line:
        new_lines.append(line)
        new_lines.append('\tfor child in hotel_container.get_children():\n')
        new_lines.append('\t\tif child.name != "NewHotelCard":\n')
        new_lines.append('\t\t\tchild.queue_free()\n')
        new_lines.append('\t_hotels = SaveManager.get_hotels(GameState.active_profile_id)\n')
        new_lines.append('\thotel_count_lbl.text = "%d Hotel%s" % [_hotels.size(), "s" if _hotels.size() != 1 else ""]\n')
        new_lines.append('\tstatus_label.text = GameState.T("dashboard.status.no_hotels") if _hotels.is_empty() else ""\n')
        new_lines.append('\tfor i in _hotels.size():\n')
        new_lines.append('\t\thotel_container.add_child(_create_hotel_card(_hotels[i], i))\n\n')
        skip = True
        continue
        
    if skip:
        if 'func _create_hotel_card(hotel: Dictionary, index: int)' in line:
            new_lines.append('func _create_hotel_card(hotel: Dictionary, index: int) -> Control:\n')
            new_lines.append('\tvar card = HOTEL_CARD_SCENE.instantiate()\n')
            new_lines.append('\tcard.setup(hotel)\n')
            new_lines.append('\tcard.sig_play_requested.connect(_start_hotel_by_id)\n')
            new_lines.append('\tcard.sig_delete_requested.connect(_delete_hotel)\n')
            new_lines.append('\treturn card\n\n')
        elif 'func _start_hotel_by_id(hotel_id: int) -> void:' in line or 'func _add_stat' in line:
            pass # we are already skipping
        elif 'func _on_new_hotel_pressed()' in line:
            skip = False
            new_lines.append(line)
        continue
        
    if 'func _start_hotel(index: int) -> void:' in line:
        new_lines.append('func _start_hotel_by_id(hotel_id: int) -> void:\n')
        new_lines.append('\tGameState.active_hotel_id = hotel_id\n')
        new_lines.append('\tget_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")\n\n')
        skip = True # skip old start_hotel
        continue
        
    if 'func _unhandled_input' in line and skip:
        skip = False
        new_lines.append(line)
        continue

    new_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print("Dashboard.gd modified successfully!")
