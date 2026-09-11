# Gourmet-Sterne & Inspektor (Feature Konzept)

*Referenz: ANG-165, basierend auf dem Archiv-Konzept "Michelin"*

Um Namenskonflikte mit realen Marken zu vermeiden, nutzt HO·MA·SIM das System der **Gourmet-Sterne** (1 bis 3 Sterne). Diese Sterne dienen als Fortschritts-Gate für höhere Techtree-Tiers und signalisieren höchste Qualitätsstandards.

## Das Inspektor-Event (ANG-165)

Sterne werden **nicht** automatisch im Hintergrund vergeben oder abgezogen. Sie erfordern immer den physischen Besuch des **Gourmet-Inspektors** (Zufallsevent). Da HO·MA·SIM auf eine lebendige Simulation setzt, sollte der Inspektor als echter Gast auftauchen, die Gastro nutzen und dann seine Bewertung abgeben.

### Ablauf des Inspektor-Besuchs (✅ Vollständig implementiert)
1. **Spawn-Bedingung:** Das Event triggert zufällig, wenn die Voraussetzungen erfüllt sind.
2. **Der Besuch (Anonym):** Der Inspektor taucht unangekündigt als "getarnter" Gast (z.B. als Single-Gast) auf. Sein Status (`is_inspector = true`, `cover_type = "single"`) sorgt dafür, dass er sich äußerlich nicht von normalen Gästen unterscheidet.
3. **Auswertung beim Checkout:**
   - Beim Checkout (`GuestManager.evaluate_gourmet_stars()`) werden die Werte gesammelt.
   - Der Inspektor sendet seine Bewertung über das Signal `sig_inspector_report_ready`, was im UI das **Inspektor-Bericht-Modal** öffnet.
   - Erst wenn der Spieler diesen Bericht schließt, startet die Sterne-Verleihung (oder Aberkennung) via `ModalStarAchieved`.
   - Besonderheit: Das Erreichen des 1. Sterns friert aktuell die EXP ein (`exp_frozen`) und beendet die Pre-Alpha-Phase.

## Schwellenwerte für den 1. Stern
Der 1. Stern ist die Voraussetzung, um ins Tier 2 des Techtrees zu gelangen.

**Kriterien für die Vergabe (laut ANG-165):**
- **Voraussetzung:** Technologie `G1.4` erforscht.
- **Service-Qualität:** Ø Gäste-Satisfaction ≥ 70% (Rolling Average der letzten Gäste).
- **Sauberkeit:** Ø Cleanliness aller Zimmer ≥ 75%.
- **Reputation:** Ruf-Score ≥ 600.
- **Kapazität:** Mindestens 10 Zimmer vorhanden.

## Verknüpfung mit dem Techtree
Die Gourmet-Sterne agieren als Gatekeeper im Techtree:
- **Tier 1:** Standard, frei verfügbar nach Bau des Forschungsbüros.
- **Tier 2:** Benötigt eine bestimme Anzahl an Forschungen in Tier 1 + **⭐ 1. Gourmet-Stern**.
