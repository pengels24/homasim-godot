extends Node2D

@onready var blocks_node = %Blocks
@onready var camera = %Camera
@onready var fader = %Fader
@onready var logo = %Logo
@onready var timer = %Timer
@onready var lbl_skip = %LblSkip

var sequence = []
var current_idx = 0
var is_skipping = false

func _ready() -> void:
    for i in range(1, 23):
        var tex = load("res://assets/images/intro/sequence/seq_%02d.png" % i)
        
        var sprite = Sprite2D.new()
        sprite.texture = tex
        # Scale image up to cover the 1920x1080 screen (since images are 1024x576)
        sprite.scale = Vector2(1.875, 1.875)
        # Crop the UI out (Top bar + Pause banner = ~90px, Bottom UI = ~56px)
        sprite.region_enabled = true
        sprite.region_rect = Rect2(0, 90, 1024, 430)
        
        sprite.visible = false
        blocks_node.add_child(sprite)
        sequence.append(sprite)
        
    fader.modulate.a = 0
    logo.modulate.a = 0
    
    # Show the first frame immediately
    if sequence.size() > 0:
        sequence[0].visible = true
        sequence[0].modulate.a = 1.0
        
    timer.wait_time = 0.5
    timer.start()

func _on_timer_timeout() -> void:
    if current_idx < sequence.size() - 1:
        var old_sprite = sequence[current_idx]
        current_idx += 1
        var new_sprite = sequence[current_idx]
        
        new_sprite.visible = true
        new_sprite.modulate.a = 0.0
        
        # Crossfade
        var tw = create_tween()
        tw.tween_property(new_sprite, "modulate:a", 1.0, 0.4)
    else:
        timer.stop()
        _start_outro()

func _start_outro() -> void:
    if is_skipping: return
    
    # We could zoom the camera, but the sprites are already cropped
    # Let's just do a slow zoom-in on the final hotel image
    var tw = create_tween()
    tw.set_trans(Tween.TRANS_SINE)
    tw.tween_property(camera, "zoom", Vector2(1.1, 1.1), 3.0)
    
    await get_tree().create_timer(1.5).timeout
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
