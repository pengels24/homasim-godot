extends Control
class_name ConfirmModal
## Wiederverwendbares Bestätigungs-Modal im Spiel-Design.
## Aufruf: confirm_modal.ask("Titel", "Nachricht")
## Signale: confirmed / cancelled

signal confirmed
signal cancelled

@onready var _title_label:   Label  = $Center/Card/Margin/VBox/Title
@onready var _message_label: Label  = $Center/Card/Margin/VBox/Message
@onready var _btn_confirm:   Button = $Center/Card/Margin/VBox/Buttons/BtnConfirm
@onready var _btn_cancel:    Button = $Center/Card/Margin/VBox/Buttons/BtnCancel


func _ready() -> void:
	_btn_confirm.pressed.connect(_on_confirmed)
	_btn_cancel.pressed.connect(_on_cancelled)


# ── Öffentliche API ───────────────────────────────────────────────────────────

func ask(
	title:        String,
	message:      String,
	confirm_text: String = "Bestätigen",
	cancel_text:  String = "Abbrechen"
) -> void:
	_title_label.text   = title
	_message_label.text = message
	_btn_confirm.text   = confirm_text
	_btn_cancel.text    = cancel_text
	visible = true


# ── Handler ───────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_cancelled()


func _on_confirmed() -> void:
	visible = false
	confirmed.emit()


func _on_cancelled() -> void:
	visible = false
	cancelled.emit()
