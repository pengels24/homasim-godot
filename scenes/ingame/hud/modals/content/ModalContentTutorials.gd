extends HBoxContainer

@onready var item_list: ItemList = %TutorialList
@onready var title_label: Label = %Title
@onready var desc_label: RichTextLabel = %Desc
@onready var texture_rect: TextureRect = %TextureRect

var _tutorials: Array = []

func _ready() -> void:
	if TutorialManager:
		_tutorials = TutorialManager.get_unlocked_data()
	else:
		_tutorials = []
		
	_populate_list()
	
	item_list.item_selected.connect(_on_item_selected)
	if _tutorials.size() > 0:
		item_list.select(0)
		_on_item_selected(0)
	else:
		_clear_display()

func _populate_list() -> void:
	item_list.clear()
	for tut in _tutorials:
		var title_key = tut.get("title_key", "")
		var text = GameState.T(title_key) if GameState else title_key
		item_list.add_item(text)

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _tutorials.size(): return
	var tut = _tutorials[index]
	
	var title_key = tut.get("title_key", "")
	var desc_key = tut.get("desc_key", "")
	var image_path = tut.get("image", "")
	
	title_label.text = GameState.T(title_key) if GameState else title_key
	desc_label.text = GameState.T(desc_key) if GameState else desc_key
	
	if image_path != "":
		texture_rect.texture = load(image_path)
		texture_rect.show()
	else:
		texture_rect.hide()

func _clear_display() -> void:
	title_label.text = GameState.T("ui.tutorial.empty", "Noch keine Tutorials freigeschaltet.")
	desc_label.text = ""
	texture_rect.hide()
