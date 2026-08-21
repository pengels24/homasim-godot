extends CanvasLayer

var WEBHOOK_URL = "https://hook.eu1.make.com/1e63jmksnaqyvbifdflkw8guqmnn64ge"
var http_request: HTTPRequest

# --- EINSTELLUNGEN FÜR ZEITRAFFER ---
var RECORD_DURATION = 30.0 # Wie lange soll aufgenommen werden (in Sekunden)
var FPS = 10 # Wie viele Bilder pro Sekunde (10 FPS = 300 Bilder bei 30s)

# --- INTERNE VARIABLEN ---
var is_recording = false
var record_timer = 0.0
var frame_timer = 0.0
var frame_count = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128 # Sehr weit vorne
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func _input(event: InputEvent) -> void:
	# Nur fur Entwickler/im Debug-Build
	if not OS.is_debug_build():
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		# F12 = Einzelner Screenshot
		if event.keycode == KEY_F12 and event.ctrl_pressed and event.alt_pressed:
			get_viewport().set_input_as_handled()
			_trigger_social_share()
		# F11 = 30 Sekunden Video-Aufnahme
		if event.keycode == KEY_F11 and event.ctrl_pressed and event.alt_pressed:
			get_viewport().set_input_as_handled()
			_start_recording()

func _process(delta: float) -> void:
	if not is_recording:
		return
		
	record_timer += delta
	frame_timer += delta
	
	# Neues Bild aufnehmen?
	if frame_timer >= (1.0 / FPS):
		frame_timer -= (1.0 / FPS)
		_capture_frame()
		
	# Aufnahme beenden?
	if record_timer >= RECORD_DURATION:
		_stop_recording_and_encode()

func _start_recording() -> void:
	if is_recording or http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
		
	# Aufräumen des alten Ordners
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("timelapse"):
		dir.make_dir("timelapse")
	else:
		_cleanup_timelapse_folder()
		
	is_recording = true
	record_timer = 0.0
	frame_timer = 0.0
	frame_count = 0
	
	if typeof(Toast) == TYPE_OBJECT and Toast.has_method("show"):
		Toast.show("Video-Aufnahme (" + str(RECORD_DURATION) + "s) gestartet...", "info")
	print("[DevSocialSharer] Video recording started...")

func _capture_frame() -> void:
	var img = get_viewport().get_texture().get_image()
	frame_count += 1
	var path = "user://timelapse/frame_%04d.png" % frame_count
	img.save_png(path)

func _stop_recording_and_encode() -> void:
	is_recording = false
	if typeof(Toast) == TYPE_OBJECT and Toast.has_method("show"):
		Toast.show("Aufnahme fertig! Rendere MP4 (FFmpeg)...", "build")
		
	print("[DevSocialSharer] Recording finished. Encoding " + str(frame_count) + " frames...")
	
	# Ein Frame warten, damit der Toast angezeigt wird
	await get_tree().create_timer(0.1).timeout 
	
	# Pfade für FFmpeg zusammenbauen
	var user_dir = ProjectSettings.globalize_path("user://timelapse")
	var input_pattern = user_dir + "/frame_%04d.png"
	var output_file = user_dir + "/output.mp4"
	var ffmpeg_path = ProjectSettings.globalize_path("res://ffmpeg.exe")
	
	var args = [
		"-y", # Datei ueberschreiben falls existent
		"-framerate", str(FPS),
		"-i", input_pattern,
		"-c:v", "libx264",
		"-preset", "ultrafast",
		"-crf", "25",
		"-pix_fmt", "yuv420p",
		output_file
	]
	
	# FFmpeg synchron aufrufen (das Spiel friert fuer 1-2 Sekunden kurz ein)
	var output = []
	var exit_code = OS.execute(ffmpeg_path, args, output, true)
	
	if exit_code != 0:
		if typeof(Toast) == TYPE_OBJECT and Toast.has_method("show"):
			Toast.show("FFmpeg Fehler! (Fehlende exe?)", "personal")
		print("[DevSocialSharer] FFmpeg Error: ", output)
		return
		
	print("[DevSocialSharer] Encoding successful! Reading MP4...")
	
	# MP4 Datei laden
	var file = FileAccess.open("user://timelapse/output.mp4", FileAccess.READ)
	if file:
		var buffer = file.get_buffer(file.get_length())
		file.close()
		_send_to_make(buffer, "timelapse.mp4", "video/mp4")
		if typeof(Toast) == TYPE_OBJECT and Toast.has_method("show"):
			Toast.show("Sende MP4 an Make.com...", "info")
	else:
		print("[DevSocialSharer] Could not read output.mp4")

func _cleanup_timelapse_folder() -> void:
	var dir = DirAccess.open("user://timelapse")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()

func _trigger_social_share() -> void:
	if typeof(Toast) == TYPE_OBJECT and Toast.has_method("show"):
		Toast.show("Sende Screenshot an Make.com...", "info")
	
	print("[DevSocialSharer] Taking screenshot...")
	
	# Auf den nachsten Frame warten (sauberer Render)
	await get_tree().process_frame
	
	var img = get_viewport().get_texture().get_image()
	var screenshot_buffer = img.save_png_to_buffer()
	
	_send_to_make(screenshot_buffer, "screenshot.png", "image/png")

func _get_context_string() -> String:
	var date_dict = Time.get_datetime_dict_from_system()
	var date_str = "%04d-%02d-%02d %02d:%02d" % [date_dict.year, date_dict.month, date_dict.day, date_dict.hour, date_dict.minute]
	
	var hotel_name = "Main Menu"
	var context = "Lobby"
	
	if is_instance_valid(GameState) and typeof(GameState.get("selected_hotel")) == TYPE_DICTIONARY:
		hotel_name = "HO·MA·SIM - Pre-ALPHA" # Temporrer Override fr Screenshots
		context = "Ingame"
		
		# Pruefen, ob ein aktives Modal offen ist
		var hud = get_tree().root.get_node_or_null("Main/HUD")
		if hud:
			# Finde Modals
			for child in hud.get_children():
				if "Modal" in child.name and child.visible:
					context = "Modal: " + child.name
					break
	
	return "%s - %s - %s" % [date_str, hotel_name, context]

func _send_to_make(file_buffer: PackedByteArray, filename: String, content_type: String) -> void:
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		print("[DevSocialSharer] Request already in progress.")
		return
		
	var boundary = "WebKitFormBoundary" + str(randi())
	var body = PackedByteArray()
	
	var payload = {
		"content": _get_context_string()
	}
	
	body.append_array(("--" + boundary + "\r\n").to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"payload_json\"\r\n\r\n").to_utf8_buffer())
	body.append_array((JSON.stringify(payload) + "\r\n").to_utf8_buffer())
	
	body.append_array(("--" + boundary + "\r\n").to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"file\"; filename=\"" + filename + "\"\r\n").to_utf8_buffer())
	body.append_array(("Content-Type: " + content_type + "\r\n\r\n").to_utf8_buffer())
	body.append_array(file_buffer)
	body.append_array(("\r\n").to_utf8_buffer())
	
	body.append_array(("--" + boundary + "--\r\n").to_utf8_buffer())
	
	var headers = ["Content-Type: multipart/form-data; boundary=" + boundary]
	
	var err = http_request.request_raw(WEBHOOK_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("[DevSocialSharer] Failed to start HTTP request")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	# Putze den Ordner sofort wenn der Request durch ist
	_cleanup_timelapse_folder()
	
	var response_text = _body.get_string_from_utf8()
	if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 204 or response_code == 201 or response_code == 202):
		if typeof(Toast) == TYPE_OBJECT and Toast.has_method("show"):
			Toast.show("Erfolgreich an Make.com gesendet!", "build")
		print("[DevSocialSharer] Successfully sent to make.com! Response: ", response_text)
	else:
		if typeof(Toast) == TYPE_OBJECT and Toast.has_method("show"):
			Toast.show("Fehler beim Senden (" + str(response_code) + ")", "personal")
		print("[DevSocialSharer] Request failed. Result: ", result, " Code: ", response_code, " Body: ", response_text)
