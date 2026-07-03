extends VBoxContainer

@onready var lbl_income: Label = %LblIncome
@onready var lbl_expense: Label = %LblExpense
@onready var lbl_total: Label = %LblTotal

@onready var btn_time_left: Button = %BtnTimeLeft
@onready var btn_time_right: Button = %BtnTimeRight
@onready var lbl_time: Label = %LblTime

@onready var btn_cat_left: Button = %BtnCatLeft
@onready var btn_cat_right: Button = %BtnCatRight
@onready var lbl_cat: Label = %LblCat

@onready var list_container: VBoxContainer = %ListContainer

var _sel_data: Dictionary = {}

var time_idx: int = 0
var cat_idx: int = 0
var type_idx: int = 0

const TIME_TEXTS = ["finances.time.today", "finances.time.yesterday", "finances.time.all"]
const TIME_VALS = ["today", "yesterday", "all"]

const CAT_TEXTS = ["finances.cat.all", "finances.cat.construction", "finances.cat.personal", "finances.cat.gastro", "finances.cat.quest", "finances.cat.research"]
const CAT_VALS = ["all", "construction", "Personal", "gastro", "quest", "research"]

const TYPE_TEXTS = ["finances.type.all", "finances.type.income", "finances.type.expense"]
const TYPE_VALS = ["all", "income", "expense"]

# =============================================================================
func _ready() -> void:
	$Panel/Margin/VBox/Header/LblDay.text = GameState.T("finances.header.time")
	$Panel/Margin/VBox/Header/LblCat.text = GameState.T("finances.header.cat")
	$Panel/Margin/VBox/Header/LblDesc.text = GameState.T("finances.header.desc")
	$Panel/Margin/VBox/Header/LblAmount.text = GameState.T("finances.header.amount")
	$Label.text = GameState.T("finances.book.title")
	%BtnTimeLeft.pressed.connect(_on_btn_time_left)
	%BtnTimeRight.pressed.connect(_on_btn_time_right)
	
	%BtnCatLeft.pressed.connect(_on_btn_cat_left)
	%BtnCatRight.pressed.connect(_on_btn_cat_right)
	
	%BtnTypeLeft.pressed.connect(_on_btn_type_left)
	%BtnTypeRight.pressed.connect(_on_btn_type_right)
	
	_update_list()

func _on_btn_time_left() -> void:
	time_idx -= 1
	if time_idx < 0: time_idx = TIME_VALS.size() - 1
	_update_list()

func _on_btn_time_right() -> void:
	time_idx = (time_idx + 1) % TIME_VALS.size()
	_update_list()

func _on_btn_cat_left() -> void:
	cat_idx -= 1
	if cat_idx < 0: cat_idx = CAT_VALS.size() - 1
	_update_list()

func _on_btn_cat_right() -> void:
	cat_idx = (cat_idx + 1) % CAT_VALS.size()
	_update_list()

func _on_btn_type_left() -> void:
	type_idx -= 1
	if type_idx < 0: type_idx = TYPE_VALS.size() - 1
	_update_list()

func _on_btn_type_right() -> void:
	type_idx = (type_idx + 1) % TYPE_VALS.size()
	_update_list()

# =============================================================================
func _update_list() -> void:
	%LblTime.text = GameState.T(TIME_TEXTS[time_idx])
	%LblCat.text = GameState.T(CAT_TEXTS[cat_idx])
	%LblType.text = GameState.T(TYPE_TEXTS[type_idx])
	
	var time_filter = TIME_VALS[time_idx]
	var cat_filter = CAT_VALS[cat_idx]
	var type_filter = TYPE_VALS[type_idx]
	
	# Update summary titles
	if time_filter == "today":
		%TitleIncome.text = GameState.T("finances.title.income.today")
		%TitleExpense.text = GameState.T("finances.title.expense.today")
		%TitleTotal.text = GameState.T("finances.title.total.today")
	elif time_filter == "yesterday":
		%TitleIncome.text = GameState.T("finances.title.income.yesterday")
		%TitleExpense.text = GameState.T("finances.title.expense.yesterday")
		%TitleTotal.text = GameState.T("finances.title.total.yesterday")
	else:
		%TitleIncome.text = GameState.T("finances.title.income.all")
		%TitleExpense.text = GameState.T("finances.title.expense.all")
		%TitleTotal.text = GameState.T("finances.title.total.all")
	
	for child in list_container.get_children():
		child.queue_free()
		
	var txs: Array = GameState.selected_hotel.get("transactions", [])
	
	var current_day = GameState.selected_hotel.get("day", 1)
	
	var income_today: int = 0
	var expense_today: int = 0
	
	var items_added: int = 0
	var max_items: int = 1000
	
	# Iterate backwards to show newest first
	for i in range(txs.size() - 1, -1, -1):
		var tx = txs[i]
		
		# Filtering
		if time_filter == "today" and tx["day"] != current_day:
			continue
		if time_filter == "yesterday" and tx["day"] != current_day - 1:
			continue
			
		if cat_filter != "all":
			# quest and reward are both mapped to quest filter
			if cat_filter == "quest" and tx["category"] not in ["quest", "reward"]:
				continue
			elif cat_filter != "quest" and tx["category"] != cat_filter:
				continue
				
		var t_amt = tx["amount"]
		if type_filter == "income" and t_amt <= 0:
			continue
		if type_filter == "expense" and t_amt >= 0:
			continue
				
		# Calculate sum ONLY for items that match the filter!
		if t_amt > 0:
			income_today += t_amt
		else:
			expense_today += t_amt
				
		if items_added >= max_items:
			continue
			
		_add_transaction_row(tx)
		items_added += 1

	lbl_income.text = "+%d €" % income_today
	lbl_expense.text = "%d €" % expense_today
	var total = income_today + expense_today
	if total >= 0:
		lbl_total.text = "+%d €" % total
		lbl_total.add_theme_color_override("font_color", Color("366e4d"))
	else:
		lbl_total.text = "%d €" % total
		lbl_total.add_theme_color_override("font_color", Color("b02e3b"))

# =============================================================================
func _add_transaction_row(tx: Dictionary) -> void:
	var row = HBoxContainer.new()
	
	var lbl_t = Label.new()
	lbl_t.custom_minimum_size = Vector2(130, 0)
	lbl_t.theme_type_variation = &"DescLabelLarge"
	lbl_t.text = GameState.T("finances.row.day") % [tx["day"], int(tx["time"] / 60.0), tx["time"] % 60]
	row.add_child(lbl_t)
	
	var lbl_c = Label.new()
	lbl_c.custom_minimum_size = Vector2(200, 0)
	lbl_c.theme_type_variation = &"ValueLabelLarge"
	var t_cat = tx["category"]
	var cat_name: String
	match t_cat:
		"construction": cat_name = GameState.T("finances.cat.label.construction")
		"Personal":     cat_name = GameState.T("finances.cat.label.personal")
		"gastro":       cat_name = GameState.T("finances.cat.label.gastro")
		"quest", "reward": cat_name = GameState.T("finances.cat.label.quest")
		"research":     cat_name = GameState.T("finances.cat.label.research")
		"system":       cat_name = GameState.T("finances.cat.label.system")
		"room":         cat_name = GameState.T("finances.cat.label.room")
		_:              cat_name = t_cat  # Fallback: raw value
	lbl_c.text = cat_name
	row.add_child(lbl_c)
	
	var lbl_desc = Label.new()
	lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_desc.theme_type_variation = &"ValueLabelLarge"
	lbl_desc.text = tx["description"]
	row.add_child(lbl_desc)
	
	var lbl_amount = Label.new()
	lbl_amount.custom_minimum_size = Vector2(120, 0)
	lbl_amount.theme_type_variation = &"ValueLabelLarge"
	lbl_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if tx["amount"] > 0:
		lbl_amount.add_theme_color_override("font_color", Color("366e4d"))
		lbl_amount.text = "+%d %s" % [tx["amount"], GameState.T("currency.symbol")]
	else:
		lbl_amount.add_theme_color_override("font_color", Color("b02e3b"))
		lbl_amount.text = "%d %s" % [tx["amount"], GameState.T("currency.symbol")]
	row.add_child(lbl_amount)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	row.add_child(spacer)
	
	list_container.add_child(row)

# =============================================================================
func _setup_selector(id: String, btn_left: Button, btn_right: Button, label: Label, texts: Array, vals: Array, current_val: Variant, callback: Callable) -> void:
	var idx: int = vals.find(current_val)
	if idx == -1: idx = 0

	_sel_data[id] = {
		"texts": texts,
		"vals": vals,
		"idx": idx,
		"label": label,
		"callback": callback
	}
	label.text = GameState.T(texts[idx])
	btn_left.pressed.connect(func(): _shift_selector(id, -1))
	btn_right.pressed.connect(func(): _shift_selector(id, 1))

# =============================================================================
func _shift_selector(id: String, direction: int) -> void:
	var data: Dictionary = _sel_data[id]
	data.idx += direction

	if data.idx < 0:
		data.idx = data.vals.size() - 1
	elif data.idx >= data.vals.size():
		data.idx = 0

	data.label.text = GameState.T(data.texts[data.idx])
	data.callback.call(data.vals[data.idx])
