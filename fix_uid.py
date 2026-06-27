import os

file_path = r'd:\game-dev\homasim-godot\scenes\main_menu\ModalContentDisclaimer.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('uid="uid://dsvdf3ytd4a3e"', 'uid="uid://cxh0s5seikuc5"')
content = content.replace('uid="uid://cfeb4s3xkj78v"', 'uid="uid://b802q2dq055uh"')
content = content.replace('uid="uid://dqk3x3y6a2y8w"', 'uid="uid://2rxcfg77t4wa"')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated UIDs")