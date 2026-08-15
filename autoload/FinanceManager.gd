# autoload FinanceManager

extends Node

var _transaction_counter: int = 1


# =============================================================================
## Trägt eine neue Buchung in das Kassenbuch ein und aktualisiert den Kontostand.
func add_transaction(amount: int, category: String, description: String, log_it: bool = true) -> void:

  # 1. Sicherstellen, dass überhaupt ein Hotel geladen ist
  if GameState.selected_hotel.is_empty():
    return

  # 2. Aktuelle Zeit und Tag abrufen
  var current_day: int = GameState.selected_hotel.get("day", 1)
  var current_time: int = TimeManager.get_game_time()

  # 3. Eindeutige ID generieren (z. B. "TX_00001")
  var tx_id := "TX_%05d" % _transaction_counter
  _transaction_counter += 1

  # 4. Den Datensatz (die "Zeile" im Buch) bauen
  var transaction := {
    "id": tx_id,
    "day": current_day,
    "time": current_time,
    "amount": amount,
    "category": category,
    "description": description
  }

  # 5. Im GameState speichern
  # (Erstellt das Array automatisch, falls es beim allerersten Mal noch fehlt)
  if not GameState.selected_hotel.has("transactions"):
    GameState.selected_hotel["transactions"] = []

  GameState.selected_hotel["transactions"].append(transaction)

  # 6. Das Geld über deine bestehende GameState-Logik aktualisieren
  # (Das feuert auch automatisch dein sig_hotel_money_changed Signal!)
  GameState.add_money(amount)
  
  if amount != 0:
      SoundManager.play("cash")
      
  if log_it:
      var log_desc: String = description
      if "|" in description:
          var parts := description.split("|")
          var translated := GameState.T(parts[0])
          
          # Sicherstellen, dass genügend Platzhalter für die Argumente vorhanden sind
          var needed_placeholders = parts.size() - 1
          var actual_placeholders = translated.count("%s")
          
          while actual_placeholders < needed_placeholders:
              translated += " %s"
              actual_placeholders += 1
              
          if parts.size() == 2:
              log_desc = translated % parts[1]
          elif parts.size() >= 3:
              log_desc = translated % [parts[1], parts[2]]
          else:
              log_desc = translated
      ActivityLog.add(category, log_desc, current_day, current_time)
