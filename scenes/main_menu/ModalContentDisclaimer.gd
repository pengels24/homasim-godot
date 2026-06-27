extends VBoxContainer

@onready var label: RichTextLabel = %RichTextLabel
@onready var check_dont_show: CheckBox = %CheckDontShow
@onready var btn_ok: Button = %BtnOk

func _ready() -> void:
    label.text = GameState.T("ui.disclaimer.text")
    check_dont_show.text = GameState.T("ui.disclaimer.dont_show")
    btn_ok.text = GameState.T("ui.disclaimer.ok")
    
    btn_ok.pressed.connect(_on_ok_pressed)

func _on_ok_pressed() -> void:
    if check_dont_show.button_pressed:
        SettingsManager.dont_show_disclaimer = true
        SettingsManager.save()
    
    # Finde das StandardModal-Parent und schließe es
    var p = get_parent()
    while p and not p.has_method("close"):
        p = p.get_parent()
    if p and p.has_method("close"):
        p.close()