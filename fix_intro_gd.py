import os

code = """extends Node2D

@onready var blocks_node = %Blocks
@onready var camera = %Camera
@onready var fader = %Fader
@onready var logo = %Logo
@onready var timer = %Timer
@onready var lbl_skip = %LblSkip

var full_texture: Texture2D
var blocks = []
var grid_size = Vector2(30, 25)

var is_skipping = false

func _ready() -> void:
    full_texture = load("res://assets/images/intro/full_hotel.png")
    
    var tex_size = full_texture.get_size()
    var block_w = tex_size.x / grid_size.x
    var block_h = tex_size.y / grid_size.y
    
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            var sprite = Sprite2D.new()
            sprite.texture = full_texture
            sprite.region_enabled = true
            sprite.region_rect = Rect2(x * block_w, y * block_h, block_w, block_h)
            
            var top_left = -tex_size / 2.0
            sprite.position = top_left + Vector2(x * block_w + block_w/2.0, y * block_h + block_h/2.0)
            
            sprite.visible = false
            blocks_node.add_child(sprite)
            blocks.append(sprite)
            
    blocks.shuffle()
    
    fader.modulate.a = 0
    logo.modulate.a = 0
    
    timer.wait_time = 0.015
    timer.start()

func _on_timer_timeout() -> void:
    if blocks.size() > 0:
        var b = blocks.pop_back()
        b.visible = true
    else:
        timer.stop()
        _start_outro()

func _start_outro() -> void:
    if is_skipping: return
    
    var tw = create_tween()
    tw.set_trans(Tween.TRANS_SINE)
    tw.tween_property(camera, "zoom", Vector2(0.8, 0.8), 2.0)
    
    await get_tree().create_timer(1.0).timeout
    if is_skipping: return
    
    var tw2 = create_tween()
    tw2.tween_property(fader, "modulate:a", 1.0, 1.0)
    await tw2.finished
    if is_skipping: return
    
    lbl_skip.visible = false
    
    var tw3 = create_tween()
    tw3.tween_property(logo, "modulate:a", 1.0, 1.0)
    
    await get_tree().create_timer(3.0).timeout
    if is_skipping: return
    
    var tw4 = create_tween()
    tw4.tween_property(logo, "modulate:a", 0.0, 1.0)
    await tw4.finished
    if is_skipping: return
    
    _finish_intro()

func _input(event: InputEvent) -> void:
    if is_skipping: return
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
            _skip()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _skip()

func _skip() -> void:
    is_skipping = true
    _finish_intro()

func _finish_intro() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
"""

file_path = r'd:\game-dev\homasim-godot\scenes\intro\Intro.gd'
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed encoding of Intro.gd")