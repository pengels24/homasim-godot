import csv

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

updated_rows = []
modified = False

with open(csv_path, 'r', encoding='utf-8') as f:
    # We parse manually or use csv reader
    # Wait, if line 914 has unescaped commas, csv.reader might split it wrong.
    # Let's just read lines and fix it manually.
    pass

with open(csv_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    if line.startswith("codex.guest_luxury.title"):
        new_lines.append('codex.guest_luxury.title,VIP & Luxus,VIP & Luxury\n')
    elif line.startswith("codex.guest_luxury.desc"):
        de_desc = "Prominente und schwerreiche Gäste. Sie zahlen astronomische Summen für Übernachtungen und Services, sind aber extrem schnell verärgert, wenn die Qualität nicht ihren perfekten Standards entspricht. Sie erwarten eine hohe Luxus-Bewertung der Zimmer.\\n\\nBudget: Hoch\\nGeduld: Sehr niedrig\\nAnspruch: Perfektion\\nPlatzbedarf: Einzel- oder Doppelzimmer (Suite bevorzugt)"
        en_desc = "Celebrities and ultra-rich guests. They pay astronomical sums for stays and services but are extremely quick to anger if the quality doesn't meet their perfect standards. They expect a high luxury rating for rooms.\\n\\nBudget: High\\nPatience: Very low\\nExpectations: Perfection\\nSpace Needs: Single or Double room (Suite preferred)"
        new_lines.append(f'codex.guest_luxury.desc,"{de_desc}","{en_desc}"\n')
    else:
        new_lines.append(line)

# Now add Inspector
inspector_title = 'codex.guest_inspector.title,Gourmet-Inspektor,Gourmet Inspector\n'
inspector_desc_de = "Ein verdeckter Prüfer, der inkognito das Hotel besucht. Er bewertet die Qualität der Gastronomie, die Sauberkeit und den Gesamtzustand des Hotels. Ist er zufrieden, verleiht er einen begehrten Stern, was den Ruf deines Hotels drastisch verbessert. Ist er enttäuscht, kann er Sterne auch wieder aberkennen!\\n\\nEr verhält sich wie ein normaler Gast, nutzt alle Einrichtungen und checkt nach einigen Tagen wieder aus."
inspector_desc_en = "An undercover reviewer who visits the hotel incognito. He evaluates the quality of gastronomy, cleanliness, and the overall condition of the hotel. If satisfied, he awards a coveted star, which drastically improves your hotel's reputation. If disappointed, he can revoke stars!\\n\\nHe behaves like a normal guest, uses all facilities, and checks out after a few days."

new_lines.append(inspector_title)
new_lines.append(f'codex.guest_inspector.desc,"{inspector_desc_de}","{inspector_desc_en}"\n')

with open(csv_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("VIP guest fixed and Inspector added!")
