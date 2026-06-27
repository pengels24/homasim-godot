extends CanvasLayer

# HIER DEINE DISCORD WEBHOOK URL EINTRAGEN:
# ACHTUNG: Niemals Webhooks direkt im Code committen!
var WEBHOOK_URL = ""

@onready var btn_report: Button = $BtnReport
@onready var dim: ColorRect = $Dim
@onready var modal: PanelContainer = $Modal
@onready var email_input: LineEdit = %EmailInput
@onready var input_field: TextEdit = %Input
@onready var btn_cancel: Button = %BtnCancel
@onready var btn_send: Button = %BtnSend
@onready var status_lbl: Label = %Status
@onready var http_request: HTTPRequest = %HTTPRequest

var screenshot_buffer: PackedByteArray

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Damit das Popup auch bei pausiertem Spiel läuft
	
	var config = ConfigFile.new()
	if config.load("res://secrets.cfg") == OK:
		WEBHOOK_URL = config.get_value("Discord", "webhook_url", "")
	
	btn_report.pressed.connect(_on_report_pressed)
	btn_cancel.pressed.connect(_close_modal)
	btn_send.pressed.connect(_send_report)
	http_request.request_completed.connect(_on_request_completed)

	_apply_translations()

func _apply_translations() -> void:
	btn_report.tooltip_text = GameState.T("bugreporter.tooltip")
	var vbox = $Modal/Margin/VBox
	(vbox.get_node("Title") as Label).text = GameState.T("bugreporter.title")
	(vbox.get_node("Label") as Label).text = GameState.T("bugreporter.description.label")
	email_input.placeholder_text = GameState.T("bugreporter.email.placeholder")
	input_field.placeholder_text = GameState.T("bugreporter.desc.placeholder")
	btn_cancel.text = GameState.T("bugreporter.btn.cancel")
	btn_send.text = GameState.T("bugreporter.btn.send")

func _input(event: InputEvent) -> void:
	if dim.visible and event.is_action_pressed("ui_cancel"):
		_close_modal()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if dim.visible and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()

func _on_report_pressed() -> void:
	# Screenshot machen BEVOR das UI sichtbar wird
	btn_report.hide()
	await get_tree().process_frame
	
	var img = get_viewport().get_texture().get_image()
	screenshot_buffer = img.save_png_to_buffer()
	
	btn_report.show()
	_open_modal()

func _open_modal() -> void:
	get_tree().paused = true
	dim.show()
	modal.show()
	email_input.text = ""
	input_field.text = ""
	status_lbl.text = ""
	status_lbl.add_theme_color_override("font_color", Color.WHITE)
	btn_send.disabled = false
	input_field.grab_focus()

func _close_modal() -> void:
	dim.hide()
	modal.hide()
	get_tree().paused = false

func _send_report() -> void:
	if input_field.text.strip_edges() == "":
		status_lbl.text = "Bitte gib eine Beschreibung ein!"
		status_lbl.add_theme_color_override("font_color", Color.RED)
		return
		
	if WEBHOOK_URL == "" or WEBHOOK_URL.contains("DEINE_WEBHOOK_ID"):
		status_lbl.text = "Webhook URL nicht konfiguriert (secrets.cfg fehlt)!"
		status_lbl.add_theme_color_override("font_color", Color.RED)
		return
		
	btn_send.disabled = true
	status_lbl.text = "Sende..."
	status_lbl.add_theme_color_override("font_color", Color.YELLOW)
	
	var boundary = "----GodotBugReporterBoundary123456789"
	var body = PackedByteArray()
	
	var hotel_level = "Unknown"
	if GameState.selected_hotel and GameState.selected_hotel.has("level"):
		hotel_level = str(GameState.selected_hotel.get("level", 1))
	
	var embed_fields = [
		{"name": "OS", "value": OS.get_name(), "inline": true},
		{"name": "Godot", "value": Engine.get_version_info().string, "inline": true},
		{"name": "Hotel Level", "value": hotel_level, "inline": true}
	]
	
	if email_input.text.strip_edges() != "":
		embed_fields.append({"name": "Kontakt (E-Mail)", "value": email_input.text.strip_edges(), "inline": false})
	
	var payload = {
		"thread_name": "Bug Report - " + Time.get_datetime_string_from_system().replace("T", " "),
		"embeds": [{
			"title": "🐞 Neuer Bug Report",
			"description": input_field.text,
			"color": 16711680,
			"fields": embed_fields
		}]
	}
	
	# Payload JSON
	body.append_array(("--" + boundary + "\r\n").to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"payload_json\"\r\n\r\n").to_utf8_buffer())
	body.append_array((JSON.stringify(payload) + "\r\n").to_utf8_buffer())
	
	# Screenshot
	body.append_array(("--" + boundary + "\r\n").to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"file\"; filename=\"screenshot.png\"\r\n").to_utf8_buffer())
	body.append_array(("Content-Type: image/png\r\n\r\n").to_utf8_buffer())
	body.append_array(screenshot_buffer)
	body.append_array(("\r\n").to_utf8_buffer())
	
	# End
	body.append_array(("--" + boundary + "--\r\n").to_utf8_buffer())
	
	var headers = ["Content-Type: multipart/form-data; boundary=" + boundary]
	
	var err = http_request.request_raw(WEBHOOK_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_on_request_completed(0, 0, [], PackedByteArray())

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 204):
		status_lbl.text = "Erfolgreich gesendet! Danke!"
		status_lbl.add_theme_color_override("font_color", Color.GREEN)
		await get_tree().create_timer(1.5).timeout
		_close_modal()
	else:
		btn_send.disabled = false
		var discord_err = _body.get_string_from_utf8()
		print("Discord HTTP 400 Error: ", discord_err)
		status_lbl.text = "Fehler beim Senden! (Code %d)" % response_code
		status_lbl.add_theme_color_override("font_color", Color.RED)
