# UI Design Rules

**STRIKTE DIREKTIVE: Immer den Style Guide beachten!**
Bevor du UI-Änderungen durchführst, musst du zwingend das Dokument `wiki/06_ui_style_guide.md` lesen und die dortigen Designvorgaben strikt einhalten.

- **Panel Nesting**: Niemals ein "Glow-Panel" (`ModalPanel`) innerhalb eines anderen Glow-Panels verwenden. Das wirkt visuell zu unruhig ("too much"). Für innere Detail-Panels oder Tabellenköpfe stattdessen das `InnerPanel`-Theme oder transparente/schlichte Container verwenden.
