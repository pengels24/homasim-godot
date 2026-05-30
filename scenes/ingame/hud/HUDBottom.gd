extends Control
## Das neue Hauptmenü am unteren Bildschirmrand (Bottom-HUD).

signal sig_build_menu_toggled
signal sig_reception_toggled
signal sig_staff_toggled
signal sig_tech_tree_toggled
signal sig_sim_browser_toggled

@onready var build_menu: Button = %BuildMenu
@onready var reception: Button = %Reception
@onready var staff: Button = %Staff
@onready var tech_tree: Button = %TechTree
@onready var sim_browser: Button = %SimBrowser

# --- NEU: Die Referenzen zu den Indikatoren ---
@onready var ind_reception: Panel = %IndReception
@onready var ind_sim_browser: Panel = %IndSimBrowser

# =============================================================================
func _ready() -> void:
	# Wenn die Bohrmaschine geklickt wird, leiten wir das ebenfalls an die Funktion weiter
	build_menu.pressed.connect(func():
		print("--- [Intern] HUDBottom: Build-Button geklickt!")

		# Modus im InputHandler umschalten
		if InputHandler.current_mode == InputHandler.InputMode.NORMAL:
			InputHandler.current_mode = InputHandler.InputMode.BUILD
		elif InputHandler.current_mode == InputHandler.InputMode.BUILD:
			InputHandler.current_mode = InputHandler.InputMode.NORMAL

		# Signal feuern, damit das Baumenü (und alle anderen) reagieren können
		InputHandler.sig_hotkey_build_menu_requested.emit()
		sig_build_menu_toggled.emit()
	)

	# Alle Knöpfe verdrahten + lokalen Test-Print hinzufügen
	reception.pressed.connect(func():
		print("--- [Intern] HUDBottom: Reception-Button geklickt!")
		sig_reception_toggled.emit()
	)
	staff.pressed.connect(func():
		print("--- [Intern] HUDBottom: Staff-Button geklickt!")
		sig_staff_toggled.emit()
	)
	tech_tree.pressed.connect(func():
		print("--- [Intern] HUDBottom: TechTree-Button geklickt!")
		sig_tech_tree_toggled.emit()
	)
	sim_browser.pressed.connect(func():
		print("--- [Intern] HUDBottom: SimBrowser-Button geklickt!")
		sig_sim_browser_toggled.emit()
	)

	# Tooltips zuweisen
	build_menu.tooltip_text = GameState.T("hud.bottom.build_menu_tt")
	reception.tooltip_text  = GameState.T("hud.bottom.reception_tt")
	staff.tooltip_text      = GameState.T("hud.bottom.staff_tt")
	tech_tree.tooltip_text  = GameState.T("hud.bottom.tech_tree_tt")
	sim_browser.tooltip_text = GameState.T("hud.bottom.sim_browser_tt")

	ind_reception.modulate = Color.GREEN
	ind_sim_browser.modulate = Color.GREEN


func set_reception_locked(is_locked: bool) -> void:
	reception.disabled = is_locked
	ind_reception.visible = not is_locked


func set_reception_alert(has_waiting_guests: bool) -> void:
	ind_reception.modulate = Color.RED if has_waiting_guests else Color.GREEN


func set_browser_alert(has_news: bool) -> void:
	ind_sim_browser.modulate = Color.DARK_ORANGE if has_news else Color.GREEN


# =============================================================================
# Wird vom IngameBuild (Bausystem) aufgerufen, um den Button-State zu steuern.
# idx -1 bedeutet: Baumodus/Submenü wurde geschlossen, alles zurücksetzen.
func set_btn_active(idx: int) -> void:
	if idx == -1:
		# Fokus von allen Knöpfen nehmen, damit nichts mehr "gehighlighted" bleibt
		build_menu.release_focus()
		reception.release_focus()
		staff.release_focus()
		tech_tree.release_focus()
		sim_browser.release_focus()

