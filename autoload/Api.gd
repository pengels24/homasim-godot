extends Node

## HTTP-Singleton für alle API-Requests zum PHP-Backend.
## Speichert den Session-Cookie nach Login und sendet ihn bei jedem Request mit.

const BASE_URL := "http://localhost:8848"
const _SAVE_PATH := "user://session.cfg"

var session_cookie := "":
	set(value):
		session_cookie = value
		_save_session()

# Interne Queue, damit parallele Requests sich nicht überschreiben
var _active_requests: Array[HTTPRequest] = []


func _ready() -> void:
	_load_session()


## Sendet einen POST-Request mit Form-Data (application/x-www-form-urlencoded).
## callback: func(success: bool, data: Dictionary)
func post_form(endpoint: String, params: Dictionary, callback: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	_active_requests.append(http)

	http.request_completed.connect(
		func(result, response_code, headers, body):
			_active_requests.erase(http)
			http.queue_free()
			_handle_response(result, response_code, headers, body, callback, true)
	)

	var body_string := _encode_form_data(params)
	var request_headers := PackedStringArray([
		"Content-Type: application/x-www-form-urlencoded",
	])
	if session_cookie != "":
		request_headers.append("Cookie: " + session_cookie)

	var error := http.request(
		BASE_URL + endpoint,
		request_headers,
		HTTPClient.METHOD_POST,
		body_string
	)
	if error != OK:
		callback.call(false, {"error": "Request konnte nicht gesendet werden (Code %d)" % error})


## Sendet einen POST-Request mit JSON-Body.
## callback: func(success: bool, data: Dictionary)
func post_json(endpoint: String, data: Dictionary, callback: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	_active_requests.append(http)

	http.request_completed.connect(
		func(result, response_code, headers, body):
			_active_requests.erase(http)
			http.queue_free()
			_handle_response(result, response_code, headers, body, callback, false)
	)

	var request_headers := PackedStringArray([
		"Content-Type: application/json",
	])
	if session_cookie != "":
		request_headers.append("Cookie: " + session_cookie)

	var error := http.request(
		BASE_URL + endpoint,
		request_headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(data)
	)
	if error != OK:
		callback.call(false, {"error": "Request konnte nicht gesendet werden (Code %d)" % error})


## Sendet einen authentifizierten GET-Request mit Cookie.
## callback: func(success: bool, data: Dictionary)
func get_json(endpoint: String, callback: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	_active_requests.append(http)

	http.request_completed.connect(
		func(result, response_code, headers, body):
			_active_requests.erase(http)
			http.queue_free()
			_handle_response(result, response_code, headers, body, callback, false)
	)

	var request_headers := PackedStringArray()
	if session_cookie != "":
		request_headers.append("Cookie: " + session_cookie)

	var error := http.request(BASE_URL + endpoint, request_headers, HTTPClient.METHOD_GET)
	if error != OK:
		callback.call(false, {"error": "Request konnte nicht gesendet werden (Code %d)" % error})


## Löscht Cookie + gespeicherte Session (beim Logout).
func clear_session() -> void:
	session_cookie = ""
	var cfg := ConfigFile.new()
	cfg.save(_SAVE_PATH)


func _handle_response(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	callback: Callable,
	extract_cookie: bool
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		callback.call(false, {"error": "Netzwerkfehler (Result %d)" % result})
		return

	if extract_cookie:
		var cookie := _extract_cookie(headers)
		if cookie != "":
			session_cookie = cookie

	var json_string := body.get_string_from_utf8()
	var json := JSON.new()
	var parse_error := json.parse(json_string)

	if parse_error != OK:
		callback.call(false, {"error": "Ungültige JSON-Antwort", "raw": json_string})
		return

	var data: Variant = json.get_data()
	if data is Dictionary:
		callback.call(response_code >= 200 and response_code < 300, data)
	else:
		callback.call(response_code >= 200 and response_code < 300, {"data": data})


## Parst den Set-Cookie Header und gibt den Cookie-String zurück (ohne Flags).
func _extract_cookie(headers: PackedStringArray) -> String:
	for header in headers:
		if header.to_lower().begins_with("set-cookie:"):
			var parts := header.split(":", false, 1)
			if parts.size() >= 2:
				return parts[1].strip_edges().split(";")[0]
	return ""


## Form-Data enkodieren (key=value&key2=value2)
func _encode_form_data(params: Dictionary) -> String:
	var parts: Array[String] = []
	for key in params:
		parts.append(str(key).uri_encode() + "=" + str(params[key]).uri_encode())
	return "&".join(parts)


func _save_session() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("session", "cookie", session_cookie)
	cfg.save(_SAVE_PATH)


func _load_session() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_SAVE_PATH) == OK:
		session_cookie = cfg.get_value("session", "cookie", "")
