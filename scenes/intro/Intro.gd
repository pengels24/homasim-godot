extends Node2D

@onready var blocks_node = %Blocks
@onready var camera = %Camera
@onready var fader = %Fader
@onready var logo = %Logo
@onready var lbl_skip = %LblSkip

var sequence = []
var is_skipping = false
var avatar_rect: TextureRect
var lbl_presents: Label
var lbl_techdemo: Label
var music_player: AudioStreamPlayer

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    if has_node("/root/BugReporter"):
        get_node("/root/BugReporter").visible = false
        
    for i in range(1, 23):
        var tex = load("res://assets/images/intro/sequence/seq_%02d.png" % i)
        
        var tex_rect = TextureRect.new()
        tex_rect.texture = tex
        tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        
        tex_rect.position = Vector2(-1920/2.0, -1080/2.0)
        tex_rect.size = Vector2(1920, 1080)
        
        tex_rect.visible = false
        tex_rect.modulate.a = 0.0
        blocks_node.add_child(tex_rect)
        sequence.append(tex_rect)
        
    var canvas = get_node("CanvasLayer")
    
    var top_bar = ColorRect.new()
    top_bar.color = Color(0.02, 0.02, 0.02, 1.0)
    top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top_bar.offset_bottom = 220
    canvas.add_child(top_bar)
    canvas.move_child(top_bar, 0)
    
    var bottom_bar = ColorRect.new()
    bottom_bar.color = Color(0.02, 0.02, 0.02, 1.0)
    bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    bottom_bar.offset_top = -250
    canvas.add_child(bottom_bar)
    canvas.move_child(bottom_bar, 1)
    
    # Create Angelus texts
    avatar_rect = TextureRect.new()
    avatar_rect.texture = load("res://assets/images/angelus2010-avatar-8bit.png")
    avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    avatar_rect.custom_minimum_size = Vector2(256, 256)
    avatar_rect.set_anchors_preset(Control.PRESET_CENTER)
    avatar_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
    avatar_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
    avatar_rect.modulate.a = 0
    canvas.add_child(avatar_rect)
    
    lbl_presents = Label.new()
    lbl_presents.text = "presents"
    lbl_presents.add_theme_font_size_override("font_size", 40)
    lbl_presents.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
    lbl_presents.set_anchors_preset(Control.PRESET_CENTER)
    lbl_presents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_presents.grow_horizontal = Control.GROW_DIRECTION_BOTH
    lbl_presents.grow_vertical = Control.GROW_DIRECTION_BOTH
    lbl_presents.position.y += 180
    lbl_presents.modulate.a = 0
    canvas.add_child(lbl_presents)
    
        
    music_player = AudioStreamPlayer.new()
    music_player.stream = load("res://assets/audio/credits_music.mp3")
    music_player.volume_db = -40.0
    add_child(music_player)
    fader.modulate.a = 1.0 # Start fully black
    logo.modulate.a = 0.0
    
    lbl_techdemo = Label.new()
    lbl_techdemo.text = "TECHDEMO"
    lbl_techdemo.add_theme_font_size_override("font_size", 30)
    lbl_techdemo.add_theme_color_override("font_color", Color(0.8, 0.4, 0.1))
    lbl_techdemo.set_anchors_preset(Control.PRESET_CENTER)
    lbl_techdemo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_techdemo.grow_horizontal = Control.GROW_DIRECTION_BOTH
    lbl_techdemo.grow_vertical = Control.GROW_DIRECTION_BOTH
    lbl_techdemo.position.y += 100
    lbl_techdemo.modulate.a = 0
    canvas.add_child(lbl_techdemo)
    
    if sequence.size() > 0:
        sequence[0].visible = true
        sequence[0].modulate.a = 1.0
        
    _play_intro_sequence()

func _play_intro_sequence() -> void:
    music_player.play()
    var tw_music = create_tween()
    tw_music.tween_property(music_player, "volume_db", 0.0, 3.0)
    
    if is_skipping: return
    await get_tree().create_timer(1.0).timeout
    if is_skipping: return
    
    # 1. Angelus2010 fade in
    var tw1 = create_tween()
    tw1.tween_property(avatar_rect, "modulate:a", 1.0, 1.5)
    await tw1.finished
    if is_skipping: return
    
    # 2. Rutscht nach oben, "presents" erscheint
    var tw2 = create_tween().set_parallel(true)
    tw2.tween_property(avatar_rect, "position:y", avatar_rect.position.y - 40, 1.5).set_trans(Tween.TRANS_SINE)
    tw2.tween_property(lbl_presents, "modulate:a", 1.0, 1.5).set_delay(0.5)
    await tw2.finished
    if is_skipping: return
    
    await get_tree().create_timer(1.5).timeout
    if is_skipping: return
    
    # 3. Fade in Parzelle + Fade out texts
    var tw3 = create_tween().set_parallel(true)
    tw3.tween_property(avatar_rect, "modulate:a", 0.0, 1.0)
    tw3.tween_property(lbl_presents, "modulate:a", 0.0, 1.0)
    tw3.tween_property(fader, "modulate:a", 0.0, 1.5)
    await tw3.finished
    if is_skipping: return
    
    # 4. Erste HÃƒÂ¤lfte des Aufbaus (01-11)
    for i in range(1, 11):
        if is_skipping: return
        _show_frame(i)
        await get_tree().create_timer(0.35).timeout
        
    if is_skipping: return
    await get_tree().create_timer(0.5).timeout
        
    # 5. Parzelle fade out zu Schwarz
    var tw4 = create_tween()
    tw4.tween_property(fader, "modulate:a", 1.0, 1.0)
    await tw4.finished
    if is_skipping: return
    
    # 6. Homasim Logo fade in & out
    var tw5 = create_tween().set_parallel(true)
    tw5.tween_property(logo, "modulate:a", 1.0, 1.5)
    tw5.tween_property(lbl_techdemo, "modulate:a", 1.0, 1.5)
    await tw5.finished
    if is_skipping: return
    
    await get_tree().create_timer(2.0).timeout
    if is_skipping: return
    
    var tw6 = create_tween().set_parallel(true)
    tw6.tween_property(logo, "modulate:a", 0.0, 1.0)
    tw6.tween_property(lbl_techdemo, "modulate:a", 0.0, 1.0)
    await tw6.finished
    if is_skipping: return
    
    # 7. Parzelle fade in
    var tw7 = create_tween()
    tw7.tween_property(fader, "modulate:a", 0.0, 1.0)
    await tw7.finished
    if is_skipping: return
    
    # 8. Ablauf Rest (11-22)
    for i in range(11, sequence.size()):
        if is_skipping: return
        _show_frame(i)
        await get_tree().create_timer(0.35).timeout
        
    if is_skipping: return
    await get_tree().create_timer(1.0).timeout
    if is_skipping: return
    lbl_skip.visible = false
    
    # 9. Camera zoom out further and faster
    var tw8 = create_tween()
    tw8.tween_property(camera, "zoom", Vector2(0.85, 0.85), 2.0).set_trans(Tween.TRANS_SINE)
    await tw8.finished
    if is_skipping: return
    
    var tw9 = create_tween()
    tw9.tween_property(fader, "modulate:a", 1.0, 1.5)
    var tw_m_out = create_tween()
    tw_m_out.tween_property(music_player, "volume_db", -40.0, 1.5)
    await tw9.finished
    
    _finish_intro()

func _show_frame(idx: int) -> void:
    if idx >= sequence.size(): return
    var _old_sprite = sequence[idx - 1]
    var new_sprite = sequence[idx]
    
    new_sprite.visible = true
    new_sprite.modulate.a = 0.0
    
    var tw = create_tween()
    tw.tween_property(new_sprite, "modulate:a", 1.0, 0.25)

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
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    if has_node("/root/BugReporter"):
        get_node("/root/BugReporter").visible = true
    get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")



