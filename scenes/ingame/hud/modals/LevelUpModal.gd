extends BaseModal
class_name LevelUpModal

signal sig_rewards_claimed(money: int, fp: int)

var _previous_input_mode = null
var _reward_money: int = 0
var _reward_fp: int = 0


# =============================================================================
func _ready() -> void:
	super._ready()
	%ButtonOK.pressed.connect(_on_button_ok_pressed)


# =============================================================================
func setup(new_level: int, money_reward: int, fp_reward: int, unlock_text: String = "") -> void:
	_reward_money = money_reward
	_reward_fp = fp_reward

	%Level.text = str(new_level)
	%Money.text = "+ " + str(money_reward)
	%FP.text = "+ " + str(fp_reward)

	if unlock_text == "":
		%Unlock.visible = false
	else:
		%Unlock.visible = true
		%Unlock.text = unlock_text + " ist nun verfügbar!"


# =============================================================================
## Wir erweitern die open()-Funktion des BaseModals, um die Sterne zu zünden!
func open() -> void:
	_previous_input_mode = InputHandler.current_mode
	InputHandler.current_mode = InputHandler.InputMode.MODAL

	super.open() # Fadet das Fenster ein
	await get_tree().create_timer(0.5).timeout
	%Partikel.emitting = true # Zündet die Partikel
	%LevelUpSound.play()


# =============================================================================
func _on_button_ok_pressed() -> void:
	if _previous_input_mode != null:
		InputHandler.current_mode = _previous_input_mode
	else:
		InputHandler.current_mode = InputHandler.InputMode.NORMAL

	sig_rewards_claimed.emit(_reward_money, _reward_fp)
	close()