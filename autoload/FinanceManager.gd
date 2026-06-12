# autoload FinanceManager

extends Node

var _transaction_counter: int = 1


# =============================================================================
## Trägt eine neue Buchung in das Kassenbuch ein und aktualisiert den Kontostand.
func add_transaction(amount: int, category: String, description: String) -> void:

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
