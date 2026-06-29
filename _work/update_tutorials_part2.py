# -*- coding: utf-8 -*-
import csv

raw_data_de = """
tutorial.tip_130_exp.title = "Tipp: Erfahrung gesammelt"
tutorial.tip_130_exp.desc = "Du hast die maximalen EXP erreicht, die du ohne die Zeit laufen zu lassen erreichen kannst. Nun solltest du den Hotelbetrieb starten und mit der Zeit gehen."

tutorial.tip_fast_forward.title = "Tipp: Zeit beschleunigen"
tutorial.tip_fast_forward.desc = "Du kannst die Zeit über den Schnellvorlauf-Button beschleunigen. Bei wichtigen Ereignissen pausiert das Spiel automatisch.\nSo verpasst du keine wichtigen Dinge."
"""

raw_data_en = """
tutorial.tip_130_exp.title = "Tip: Experience gathered"
tutorial.tip_130_exp.desc = "You have reached the maximum EXP you can earn without letting the time run. Now you should start the hotel operations and go with the time."

tutorial.tip_fast_forward.title = "Tip: Fast forward time"
tutorial.tip_fast_forward.desc = "You can speed up the time using the fast-forward button. The game automatically pauses during important events.\nThis way, you won't miss anything important."
"""

data_dict_de = {}
data_dict_en = {}

for data_str, out_dict in [(raw_data_de, data_dict_de), (raw_data_en, data_dict_en)]:
    lines = data_str.strip().split('\n')
    for line in lines:
        if " = \"" in line:
            k, v = line.split(" = \"", 1)
            k = k.strip()
            v = v.strip()
            if v.endswith('"'):
                v = v[:-1]
            out_dict[k] = v.replace("\\n", "\n")

def update_csv(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
        
    for row in rows:
        if len(row) >= 3 and row[0] in data_dict_de:
            row[1] = data_dict_de[row[0]]
            row[2] = data_dict_en[row[0]]
            
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerows(rows)

update_csv('translations/language.csv')
print("Part 2 translations applied successfully!")
