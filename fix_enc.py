import os

def fix_file(filepath):
    with open(filepath, 'rb') as f:
        data = f.read()
    
    text = data.decode('utf-8')
    replacements = {
        'Ã¤': 'ä', 'Ã¶': 'ö', 'Ã¼': 'ü',
        'Ã„': 'Ä', 'Ã–': 'Ö', 'Ãœ': 'Ü',
        'ÃŸ': 'ß', 'Â´': '´'
    }
    
    for k, v in replacements.items():
        text = text.replace(k, v)
        
    with open(filepath, 'wb') as f:
        f.write(text.encode('utf-8'))

fix_file('scenes/ingame/hud/modals/content/ModalContentStaff.gd')
fix_file('translations/language.csv')
