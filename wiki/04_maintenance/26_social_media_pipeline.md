# 📖 TechDoku: Automatische Social-Media-Pipeline (Make.com + Godot)

Dieses Dokument dient als Nachschlagewerk, falls das System auf einem neuen Rechner aufgesetzt, erweitert oder debuggt werden muss.

## 🏗️ Architekturübersicht
Das System erlaubt es, direkt aus dem laufenden Spiel (Dev/Debug-Build) per Tastendruck Screenshots (oder 10s-Videos) mitsamt Kontext (Datum, Hotelname) an eine Automatisierungs-Plattform (Make.com) zu senden, welche die Inhalte dann auf Kanäle wie Discord, Instagram, Twitter oder YouTube pusht.

**Technologie-Stack:**
- **Godot (Frontend):** Sammelt UI/Spielzustand, schießt den Screenshot (oder nutzt FFmpeg für MP4-Export) und schickt einen HTTP-POST.
- **Make.com (Backend):** Nimmt als Webhook die Rohdaten entgegen und wandelt sie in native API-Calls für die jeweiligen Social-Media Plattformen um.

---

## 🛠️ 1. Godot-Integration (`DevSocialSharer.gd`)

Das Autoload-Skript `DevSocialSharer.gd` ist das Herzstück auf Spielseite. Es fängt Hotkeys ab und triggert den Export.
- **Sicherheits-Check:** Die Funktion läuft ausschließlich hinter einem `OS.is_debug_build()` Check. Spieler im Release-Build können dies nicht triggern.
- **Kontext-Sammeln:** Das Skript liest das aktuelle Datum, den Hotelnamen (hart auf "HO·MA·SIM - Pre-ALPHA" überschrieben für Screenshots) und prüft, ob Popups/Modals offen sind (z.B. "Rezeption"), um dynamische Post-Titel zu generieren.
- **Der HTTP-Request:** Das Skript baut einen `multipart/form-data` Request, der sowohl ein JSON-Objekt (`payload_json`) als auch die Binärdatei (`file` - PNG oder MP4) verschickt.

### Video-Erweiterung (FFmpeg)
Damit Godot Videos senden kann, ohne dass ein Nativ-Encoder vorliegt, speichert das Skript Bilder auf der Festplatte (`user://timelapse`) und nutzt den Befehl `OS.execute()`, um eine lokale `ffmpeg.exe` aufzurufen. Diese rendert die Frames als H.264 MP4 und übergibt die finale Datei an Make.com.
*(Wichtig: Die temporären Frames und das fertige MP4 werden im Skript durch `_cleanup_timelapse_folder()` nach erfolgreichem Senden sofort wieder rückstandslos von der Festplatte gelöscht.)*

---

## ⚙️ 2. Make.com Setup & Wiederherstellung

Falls das Make.com-Szenario versehentlich gelöscht wird, lässt es sich wie folgt in 2 Minuten neu aufbauen:

### Modul 1: Webhooks (Custom Webhook)
- Aktion: `Custom Webhook`
- Hier erhältst du die URL (z.B. `https://hook.eu1.make.com/...`). Diese URL **muss** im Godot-Skript `DevSocialSharer.gd` als Konstante `WEBHOOK_URL` eingetragen sein.
- *Wichtig:* Bevor Module angehängt werden, muss einmal auf "Run once" geklickt und in Godot ein Screenshot abgefeuert werden, damit Make die Datenstruktur (`payload_json`, `file`) erkennt!

### Modul 2: Der Router (Optional)
Ein Router direkt nach dem Webhook erlaubt es, denselben Post parallel an Discord, Instagram und Twitter zu senden.

### Modul 3a: Discord (Via HTTP-Request & Webhook)
Die sicherste Methode, um in Discord zu posten, ist die Nutzung eines Discord-Channel-Webhooks, statt des Discord-Moduls.
- **App:** `HTTP` -> `Make a request`
- **URL:** [Deine Discord Webhook-URL aus den Kanaleinstellungen]
- **Method:** `POST`
- **Body Type:** `Multipart/form-data`
- **Fields:**
  1. `Key`: `payload_json` | `Value type`: `Text` | `Value`: *[Der lila `payload_json` Baustein aus dem Make-Webhook]*
  2. `Key`: `file` | `Value type`: `File` | *[Den `file` Baustein / Custom Webhook auswählen]*

### Modul 3b: YouTube / Video Uploads
Für YouTube muss statt Bildern ein MP4 übertragen werden (erfordert FFmpeg in Godot).
- **App:** `YouTube` -> `Upload a Video`
- **Video File:** *[Das MP4-File aus dem Make-Webhook]*
- **Title:** *[Den `payload_json` Baustein aus dem Make-Webhook extrahieren/Parsen]*

---

## 🚨 Troubleshooting

1. **"Es kommt nichts in Discord an!"**
   - Prüfe in Make.com in der "History", ob der Schuss aus Godot überhaupt ankam.
   - Prüfe, ob das Szenario unten links auf "ON" (Scheduling) geschaltet ist.
   - Hat der Discord-Webhook evtl. eine neue URL bekommen?
2. **"Godot postet immer den falschen Hotelnamen"**
   - Schau im `DevSocialSharer.gd` nach dem "Temporären Override". Dieser ist Absicht für die Pre-Alpha, kann aber jederzeit entfernt werden.
3. **"Videos werden nicht gesendet"**
   - Liegt die `ffmpeg.exe` wirklich direkt im Stammverzeichnis deines Projekts (neben der `project.godot`)? Das Skript benötigt sie dort lokal.
