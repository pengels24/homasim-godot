extends PanelContainer

signal clicked(party: GuestParty)

enum Mode { WAITING, ACTIVE, CHECKOUT }

var current_mode: Mode = Mode.WAITING
var current_party: GuestParty = null
var _pulse_tween: Tween = null

@onready var _name_label: Label = %GuestName
@onready var _details_label: Label = %GuestDetails
# @onready var _icon: TextureRect = %Icon # Später für Icons

func _ready() -> void:
	# Standardmäßig Klicks erlauben
	mouse_filter = Control.MOUSE_FILTER_STOP

# -----------------------------------------------------------------------------
# DATEN BEFÜLLEN
# -----------------------------------------------------------------------------
func populate(party: GuestParty, mode: Mode) -> void:
	current_party = party
	current_mode = mode

	# Grunddaten aus deiner GuestParty-Klasse auslesen
	_name_label.text = party.get_display_name()

	# UI je nach Spalte (Modus) anpassen
	match current_mode:
		Mode.WAITING:
			_details_label.text = str(party.stay_days) + " Nächte | " + party.get_type_name()
			tooltip_text = ""

			# Beispiel für Pulsieren: Wenn Geduld kritisch wird, rot pulsieren lassen (optional)
			# if party.patience < 0.5:
			# 	_pulse_tween = EffectManager.start_ui_pulse(self)

		Mode.ACTIVE:
			_details_label.text = "Noch " + str(party.stay_days) + " Nacht(e)"
			mouse_filter = Control.MOUSE_FILTER_IGNORE # Keine Klicks in Spalte 3
			_build_tooltip()

		Mode.CHECKOUT:
			# Berechnet grob den Preis (oder du holst ihn dir später exakt vom Manager)
			var est_price = party.base_price * party.stay_days * party.satisfaction
			_details_label.text = "Zimmer " + party.room_id + " | " + "%.0f" % est_price + " €"
			tooltip_text = ""

# -----------------------------------------------------------------------------
# INTERAKTION
# -----------------------------------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_mode in [Mode.WAITING, Mode.CHECKOUT]:
			clicked.emit(current_party)

func set_highlight(active: bool) -> void:
	# Nutzt deine bestehenden Farben aus der alten Rezeption
	modulate = Color(0.20, 0.78, 0.35, 1.0) if active else Color.WHITE

func _build_tooltip() -> void:
	tooltip_text = "Zimmer: " + current_party.room_id + "\n" + \
				   "Zufriedenheit: " + str(round(current_party.satisfaction * 100)) + "%\n" + \
				   "Geduld: " + str(round(current_party.patience * 100)) + "%"

# Wichtig: Wenn die Karte gelöscht wird, Tween aufräumen!
func _exit_tree() -> void:
	if _pulse_tween:
		EffectManager.stop_ui_pulse(self, _pulse_tween)