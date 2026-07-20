extends Control

signal item_selected(id: String)
signal cancelled

@onready var title: Label = $Center/Card/Margin/VBox/Title
@onready var message: Label = $Center/Card/Margin/VBox/Message
@onready var list_container: VBoxContainer = %ListContainer
@onready var btn_cancel: Button = %BtnCancel

var SB_BLUE = preload("res://assets/UI/menu_button_blue.tres")
var SB_BLUE_PRESSED = preload("res://assets/UI/menu_button_blue_pressed.tres")
var SB_BLUE_HOVER = preload("res://assets/UI/menu_button_blue_hover.tres")

func _ready() -> void:
	btn_cancel.pressed.connect(_on_cancel)
	visible = false

func ask_list(title_text: String, desc_text: String, items: Array) -> void:
	title.text = title_text
	message.text = desc_text
	
	if desc_text == "":
		message.visible = false
	else:
		message.visible = true
		
	for child in list_container.get_children():
		child.queue_free()
		
	var idx = 0
	for item in items:
		var btn = Button.new()
		btn.text = item.get("text", "Item")
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_stylebox_override("normal", SB_BLUE)
		btn.add_theme_stylebox_override("pressed", SB_BLUE_PRESSED)
		btn.add_theme_stylebox_override("hover", SB_BLUE_HOVER)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_color_override("font_hover_color", Color(1,1,1))
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		btn.pressed.connect(func():
			visible = false
			item_selected.emit(item.get("id", ""))
		)
		
		list_container.add_child(btn)
		
		if idx == 0:
			btn.call_deferred("grab_focus")
		idx += 1

	visible = true

func _on_cancel() -> void:
	visible = false
	cancelled.emit()
