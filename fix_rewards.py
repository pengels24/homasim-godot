import os

file_path = r'd:\game-dev\homasim-godot\translations\language.csv'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('"ui.quests.reward_rank","Vergütung: ### FP | +++ ?","Reward: ### RP | +++ ?"', '"ui.quests.reward_rank","Vergütung: ### FP | *** €","Reward: ### RP | *** €"')
content = content.replace('"ui.quests.reward_quest","Belohnung: ### FP | +++ ?","Reward: ### RP | +++ ?"', '"ui.quests.reward_quest","Belohnung: ### FP | *** €","Reward: ### RP | *** €"')

# Let's just do a regex replace in case the encoding was weird
import re
content = re.sub(r'Vergütung: ### FP \| \+\+\+ [^\"]+', r'Vergütung: ### FP | *** €', content)
content = re.sub(r'Reward: ### RP \| \+\+\+ [^\"]+', r'Reward: ### RP | *** €', content)

content = re.sub(r'Belohnung: ### FP \| \+\+\+ [^\"]+', r'Belohnung: ### FP | *** €', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed reward placeholders')