import os

path = r"d:\game-dev\homasim-godot\translations\de.csv"

lines = [
    '"ui.staff.no_team","Du hast noch kein Personal eingestellt.",""',
    '"ui.staff.no_applicants","Keine Bewerber heute.",""',
    '"ui.staff.select_prompt","Bitte wähle einen Mitarbeiter aus",""',
    '"ui.staff.job","Beruf: ",""',
    '"ui.staff.daily_wage","Tagesgehalt",""',
    '"ui.staff.hire_cost","Einstellungsgebühr",""',
    '"ui.staff.fire","Kündigen",""',
    '"ui.staff.hire","Einstellen",""',
    '"ui.staff.morale","Moral",""',
    '"staff.role.housekeeping","Housekeeping",""',
    '"staff.role.maintenance","Haustechnik",""',
    '"staff.skill.cleaning_efficiency","Reinigungstempo",""',
    '"staff.skill.detail_focus","Detailfokus",""',
    '"staff.skill.motivation","Motivation",""',
    '"staff.skill.repair_knowledge","Reparaturwissen",""',
    '"staff.skill.stress_resistance","Stressresistenz",""'
]

with open(path, "a", encoding="utf-8") as f:
    f.write("\n# === STAFF UI ===\n")
    for line in lines:
        f.write(line + "\n")

print("Translations appended to de.csv!")
