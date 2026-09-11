extends BaseModal
class_name ModalStarAchieved

# =============================================================================
func _ready() -> void:
	super._ready()
	%ButtonOK.pressed.connect(_on_button_ok_pressed)
	# Wir brauchen die Rewards-Anzeige hier nicht
	%MoneyIcon.get_parent().visible = false
	%FPIcon.get_parent().visible = false

# =============================================================================
func play_animation(new_stars: int) -> void:
	%Level.text = str(new_stars)
	%Unlock.visible = true
	%Unlock.text = GameState.T("event.gourmet.stars_gained.desc")
	open()

func play_lost_animation(new_stars: int) -> void:
	%Level.text = str(new_stars)
	%Unlock.visible = true
	%Unlock.text = GameState.T("event.gourmet.stars_lost.desc")
	open()

# =============================================================================
func open() -> void:
	if InputHandler:
		InputHandler.current_mode = InputHandler.InputMode.MODAL

	super.open()
	await get_tree().create_timer(0.5).timeout
	%Partikel.emitting = true
	if %LevelUpSound:
		%LevelUpSound.play()

# =============================================================================
func _on_button_ok_pressed() -> void:
	if InputHandler:
		InputHandler.current_mode = InputHandler.InputMode.NORMAL
	close()