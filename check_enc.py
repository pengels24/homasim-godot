with open('scenes/ingame/hud/modals/content/cards/RowAssignedStaff.gd', 'rb') as f:
    text = f.read().decode('utf-8')
if 'Ã' in text:
    print('RowAssignedStaff is double encoded!')
else:
    print('Clean!')
