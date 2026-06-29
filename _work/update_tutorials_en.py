# -*- coding: utf-8 -*-
import csv

raw_data = """
tutorial.welcome.title = "The User Interface HUD" 
tutorial.welcome.desc = "Welcome to your new hotel - here is a brief overview:\nTop: Your most important running data like finances and guests, as well as the time control.\nBottom right: The music controls.\nBottom center: The main core functions (Building, Reception, Staff, etc.).\nBottom left: The view indicator to temporarily save the camera position.\nCamera control: Use WASD to move the camera and the mouse wheel to control the zoom."

tutorial.build_mode.title = "Build Mode"
tutorial.build_mode.desc = "Click on a room to build it. A ghost image of the room will appear at your mouse cursor. Use [R] to rotate the room, and [.] to move the door.\nSome rooms must be researched first!"

tutorial.reception.title = "The Reception"
tutorial.reception.desc = "At the heart of your hotel, you handle the check-in of waiting guests (assigning them to appropriate rooms) and check them out at the end of their stay."

tutorial.staff.title = "The Staffing Agency"
tutorial.staff.desc = "Through this external service provider, you can hire, fire, and assign staff to their working areas.\nEvery employee performs their tasks automatically. Some rooms also offer the option to call staff manually."

tutorial.tech_tree.title = "Research & Technology"
tutorial.tech_tree.desc = "Through the technology tree (Techtree), you can unlock new rooms and upgrades using research points (RP). Which researches are available is determined by the passage of time."

tutorial.questbook.title = "The Quest Book"
tutorial.questbook.desc = "Every new room and many of the researched upgrades fill your quest book, ensuring that completing these quests rewards you with EXP, RP, and money."

tutorial.guest_list.title = "The Guest List"
tutorial.guest_list.desc = "This is the overview of all active guests. Here you can see, among other things, their satisfaction, location, and budget at a glance.\nUsing the Pip-Cam, you can track any active guest and also jump directly to them."

tutorial.room_list.title = "The Room List"
tutorial.room_list.desc = "This list shows the status of all rooms: cleanliness, occupancy, and condition.\nUsing the Pip-Cam, you can view the room and also jump directly to it."

tutorial.finances.title = "Finances"
tutorial.finances.desc = "This is the overview of your income and expenses.\nYou can sort and filter all entries. This gives you a clear overview of your financial situation."

tutorial.sim_browser.title = "SimBrowser"
tutorial.sim_browser.desc = "Your personal in-game web portal. Here you will find reviews, statistics, and suppliers. News from the HO·MA·SIM universe is published here, as well as announcements about events and other players.\nTip: Watch out for hidden URLs!"
"""

data_dict = {}
lines = raw_data.strip().split('\n')
for i, line in enumerate(lines):
    if " = \"" in line:
        k, v = line.split(" = \"", 1)
        k = k.strip()
        v = v.strip()
        if v.endswith('"'):
            v = v[:-1]
        data_dict[k] = v.replace("\\n", "\n")

def update_csv(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
        
    for row in rows:
        if len(row) >= 3 and row[0] in data_dict:
            row[2] = data_dict[row[0]]
            
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerows(rows)

update_csv('translations/language.csv')
print("English translations applied successfully!")
