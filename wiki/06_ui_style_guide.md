# HO·MA·SIM – UI Style Guide & Theme (v2)

> Referenz: Alle UI-Elemente werden ab sofort über das zentrale `assets/UI/default_theme.tres` gesteuert. Manuelle `theme_override`-Anpassungen in den `.tscn`-Szenen sind **verboten**. Stattdessen weisen wir den Nodes die entsprechende `theme_type_variation` im Theme-Reiter zu.

---

## 1. Typografie & Labels

- **Globale Schriftart (`default_font`)**: `Jersey25-Regular.ttf`
- **Standard-Label (`Label`)**: 
  - `font_size` = 20
  - `font_color` = `#b3b3bf` (Hellgrau / `Color(0.70, 0.70, 0.75, 1)`)

### Label Type Variations

| Variation Name  | font_size | font_color                          | Verwendung                                      |
|-----------------|-----------|-------------------------------------|-------------------------------------------------|
| `HeaderLarge`   | 30px      | `#eab308` `Color(0.92, 0.70, 0.03)` | Große Titel (z.B. "Finanzen", "Einstellungen")  |
| `HeaderMedium`  | 26px      | `#eab308` `Color(0.92, 0.70, 0.03)` | Subtitel / Tab-Titel                            |
| `DescLabel`     | 18px      | `#a1a1aa` `Color(0.63, 0.63, 0.67)` | Gedimmte Beschreibungen (z.B. linke Spalte)     |
| `ValueLabel`    | 18px      | `#ffffff` `Color(1.00, 1.00, 1.00)` | Hervorgehobene Werte (z.B. rechte Spalte)       |

*(Hinweis: Für Profite/Verluste gibt es Ausnahmen mit Grün/Rot, die programmatisch im Skript vergeben werden können).*

---

## 2. Modals & Panels

Das Modal-Hintergrund-Panel ziehen wir im Theme als `ModalPanel` (Type Variation von `PanelContainer`) an. So erbt jedes Modal automatisch exakt denselben Rand und Glow.

- **Modal-Hintergrund (`bg_color`)**: `#1a1e24` `Color(0.10, 0.12, 0.14)` (Dunkelgrau-Blau)
- **Modal-Rand & Glow (`border_color` / `shadow_color`)**: `#694f06` `Color(0.41, 0.31, 0.02)` (Dunkles Gold/Bronze)
- **Corner Radius**: 8px

**WICHTIGE REGEL: Panel Nesting**
Niemals ein "Glow-Panel" (`ModalPanel`) innerhalb eines anderen Glow-Panels verwenden. Das wirkt visuell zu unruhig ("too much"). Für innere Detail-Panels oder Tabellenköpfe stattdessen das `InnerPanel`-Theme oder transparente/schlichte Container verwenden.

---

## 3. Buttons

**Grundregel für Buttons:** Die Schriftfarbe für **jeden** Button ist `#cccccc` (`Color(0.8, 0.8, 0.8)`), es sei denn, ein spezieller Button-Zustand (wie Disabled oder ein dominanter CTA) erfordert eine Ausnahme.

Wir steuern Button-Designs über die hinterlegten `.tres`-Dateien in `assets/UI/`. Die Default Button-`font_size` ist **24px**.

| Button-Typ | Hintergrundfarbe (`bg_color`) | StyleBox Normal | Verwendung |
|------------|-------------------------------|-----------------|------------|
| **Green**  | `#366e4d` `Color(0.21, 0.43, 0.30)` | `menu_button_green.tres` | Bestätigen, Speichern, Weiter |
| **Red**    | `#b02e3b` `Color(0.69, 0.18, 0.23)` | `menu_button_red.tres` | Abbrechen, Beenden, Löschen |
| **Blue**   | `#3d4891` `Color(0.24, 0.28, 0.57)` | `menu_button_blue.tres` | Navigation, Standard-Auswahl |
| **Golden** | `#694f06` `Color(0.41, 0.31, 0.02)` | `menu_button_golden.tres` | Primärer CTA, Highlight |
| **Darkblue**| `#0b0f17` `Color(0.04, 0.06, 0.09)` | `menu_button_darkblue.tres` | Dezenter Button, Nebenaktionen |

Hover-Zustände erhalten im Regelfall einen helleren Goldrand: `Color(0.89, 0.68, 0.03)`.

---

## 4. Slot-Zeilen (Save/Load Listen)

*(Werden ebenfalls noch ins globale Theme überführt, behalten aber folgende Regeln)*

- **Hintergrund (`bg_color`)**: `Color(0.08, 0.09, 0.12, 1.0)`
- **Hover/Selected (`bg_color`)**: `Color(0.10, 0.28, 0.12, 1.0)`
- **Num/Datum-Label**: `font_size`=18, `font_color`=gedimmt
- **Name-Label**: `font_size`=20, `font_color`=hell

---

## 5. Canvas Layer Reihenfolge

| Layer | Scene              |
|-------|--------------------|
| 85    | HUD                |
| 90    | PauseMenu          |
| 91    | SettingsModal      |
| 95    | InGameSaveModal    |
| 99    | DevConsole         |
| 100   | Toast              |

---

## 6. Overlay (Vollbild-Dimmer hinter Modals)

- **ColorRect** (anchor = full rect)
- **color** = `Color(0.0, 0.0, 0.0, 0.65)`
