import json
import os

path = r"d:\game-dev\homasim-godot\config\staff.json"

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

male_names = [
    "Alexander", "Benedikt", "Christopher", "David", "Florian",
    "Henry", "Manuel", "Maximilian", "Pascal", "Patrick",
    "Sebastian", "Simon", "Tobias", "Vincent"
]

female_names = [
    "Amelie", "Anna", "Charlotte", "Clara", "Elena", "Ella",
    "Emilia", "Finja", "Frieda", "Greta", "Hannah", "Ida",
    "Isabell", "Jasmin", "Johanna", "Julia", "Juna", "Klara",
    "Lara", "Laura", "Lea", "Lena", "Leni", "Lina", "Lisa",
    "Lotta", "Luisa", "Madeleine", "Maja", "Marie", "Mathilda",
    "Matilda", "Merle", "Mia", "Mila", "Nele", "Paula", "Sophie",
    "Theresa", "Vanessa", "Viktoria"
]

data["names"]["first_names_male"] = male_names
data["names"]["first_names_female"] = female_names

if "first_names" in data["names"]:
    del data["names"]["first_names"]

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print("staff.json updated with gendered first names!")
