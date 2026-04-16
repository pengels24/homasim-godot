## Version: 0.1.8
**Datum: 2026-04-17**

### Technische Änderungen

- `CLAUDE.md`: Erklärbär-Modus als permanente Direktive ergänzt – bei jeder Umsetzung wird erklärt was gemacht wird und warum, damit Peter den Code selbst verstehen und validieren kann

### Architektur-Entscheidungen & Backlog

Keine Code-Änderungen – Session fokussiert auf Verständnis, Architektur-Review und strategische Planung.

- **ANG-153** – Ingame Map: TileMap + Scene-basiertes Grid (High) – aktuelles Script-basiertes Grid auf Godot-Standard-TileMap umstellen; statische Struktur in `.tscn`, Logik bleibt in `.gd`
- **ANG-154** – Scene-Architektur: HUD, Dashboard, Credits auf `.tscn` umstellen (Medium) – konsequente Trennung Struktur/Logik
- **ANG-155** – Security: Server-seitige Validierung der Spiellogik (High) – GameState ist nur Client-Spiegel, alle Geschäftslogik wird im PHP-Backend validiert; HTTPS in Produktion
- **ANG-156** – Export-Targets: Windows/Mac/Linux für Steam (Medium) – Mobile bewusst zurückgestellt; Mac-Signierung (Apple Developer 99$/Jahr) einplanen

### Offene Backlog-Issues

- **ANG-153** – TileMap + Scene-basiertes Grid
- **ANG-154** – Scene-Architektur HUD/Dashboard/Credits
- **ANG-155** – Security / Server-seitige Validierung
- **ANG-156** – Export-Targets Steam
- **ANG-152** – Settings-Screen (ALT+S)
- **ANG-149** – Tutorial-Szene
