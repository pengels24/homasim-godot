import json

first_names = ["Anna", "Maximilian", "Laura", "Sebastian", "Julia", "Florian", "Lena", "David", "Sophie", "Alexander", "Marie", "Patrick", "Lisa", "Tobias", "Elena", "Christopher", "Vanessa", "Benedikt", "Jasmin", "Manuel", "Isabell", "Madeleine", "Vincent", "Viktoria", "Pascal", "Charlotte", "Luisa", "Simon", "Theresa", "Matilda", "Henry", "Ida", "Clara", "Johanna", "Amelie", "Leni", "Mia", "Hannah", "Lea", "Nele", "Lara", "Ella", "Emilia", "Lina", "Mila", "Klara", "Mathilda", "Greta", "Paula", "Frieda", "Finja", "Lotta", "Merle", "Juna", "Maja"]

last_names = ["Müller", "Schmidt", "Weber", "Fischer", "Lehmann", "Schneider", "Braun", "Zimmermann", "Hartmann", "Krüger", "Schmid", "Werner", "Lange", "Schmitz", "Meier", "Krause", "Maier", "Huber", "Mayer", "Herrmann", "Köhler", "Walter", "König", "Schulze", "Fuchs", "Kaiser", "Lang", "Weiß", "Peters", "Scholz", "Jung", "Möller", "Hahn", "Keller", "Vogel", "Schubert", "Roth", "Frank", "Friedrich", "Beck", "Günther", "Berger", "Winkler", "Lorenz", "Baumann", "Schuster", "Kraus", "Böhm", "Simon", "Franke", "Albrecht", "Winter", "Ludwig", "Martin", "Krämer", "Schumacher", "Vogt", "Jäger", "Stein", "Otto", "Groß", "Sommer", "Haas", "Graf", "Heinrich", "Seidel", "Ziegler", "Brandt", "Kuhn", "Schulte", "Dietrich", "Kühn", "Engel", "Pohl", "Horn", "Sauer", "Arnold", "Thomas", "Bergmann", "Busch", "Pfeiffer", "Voigt", "Götz", "Seifert", "Lindner", "Ernst", "Richter", "Wolff", "Becker", "Klein", "Schröder", "Neumann", "Schwarz", "Schmitt"]

staff_config = {
    "roles": {
        "housekeeping": {
            "name": "Housekeeping",
            "desc": "Reinigt Zimmer und sorgt für Hygiene.",
            "daily_wage": 80,
            "hire_cost": 200,
            "base_skills": {
                "cleaning_efficiency": [3, 6],
                "detail_focus": [2, 5],
                "motivation": [4, 8]
            }
        },
        "maintenance": {
            "name": "Haustechnik",
            "desc": "Repariert defekte Zimmer und hält alles in Schuss.",
            "daily_wage": 80,
            "hire_cost": 250,
            "base_skills": {
                "repair_knowledge": [3, 7],
                "stress_resistance": [4, 9],
                "motivation": [4, 8]
            }
        }
    },
    "names": {
        "first_names": sorted(list(set(first_names))),
        "last_names": sorted(list(set(last_names)))
    }
}

with open(r'd:\game-dev\homasim-godot\config\staff.json', 'w', encoding='utf-8') as f:
    json.dump(staff_config, f, indent=4, ensure_ascii=False)

print("config/staff.json generated!")
