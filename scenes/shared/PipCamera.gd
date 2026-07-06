extends MarginContainer
class_name PipCamera

var _target: Node2D = null

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D
@onready var no_signal_lbl: Label = %NoSignalLabel
@onready var no_signal_rect: ColorRect = %NoSignalRect

func _ready() -> void:
	no_signal_lbl.visible = false
	no_signal_rect.visible = false
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	
	viewport.world_2d = get_tree().root.get_viewport().world_2d
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

func set_target(target_node: Node2D) -> void:
	if is_instance_valid(_target) and _target.tree_exiting.is_connected(_on_target_exiting):
		_target.tree_exiting.disconnect(_on_target_exiting)
		
	_target = target_node
	
	if is_instance_valid(_target):
		_target.tree_exiting.connect(_on_target_exiting)
		no_signal_lbl.visible = false
		no_signal_rect.visible = false
		camera.global_position = _get_target_center()
	else:
		no_signal_lbl.visible = true
		no_signal_rect.visible = true

func _get_target_center() -> Vector2:
	if not is_instance_valid(_target): return Vector2.ZERO
	var center = _target.global_position
	if _target.has_method("get_tile_size"):
		var tile_size = _target.get_tile_size()
		center += Vector2(tile_size.x, tile_size.y) * 16.0 * 0.5 * _target.global_scale
	return center

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
		
	if is_instance_valid(_target):
		var target_visible = _target.visible
		if "avatar" in _target and _target.avatar != null:
			target_visible = _target.avatar.visible
		elif "_sprite" in _target and _target.get("_sprite") != null:
			target_visible = _target.get("_sprite").visible

		if target_visible:
			if no_signal_lbl.visible:
				no_signal_lbl.visible = false
				no_signal_rect.visible = false
			camera.global_position = camera.global_position.lerp(_get_target_center(), 5.0 * delta)
		else:
			if not no_signal_lbl.visible:
				no_signal_lbl.visible = true
				no_signal_rect.visible = true
	else:
		if not no_signal_lbl.visible:
			no_signal_lbl.visible = true
			no_signal_rect.visible = true

func _on_target_exiting() -> void:
	_target = null
	no_signal_lbl.visible = true
	no_signal_rect.visible = true

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
