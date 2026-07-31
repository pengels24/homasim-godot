import os
import re

def replace_in_file(filepath):
    if not os.path.exists(filepath):
        return
        
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Replace z11 -> z1_1, w14 -> w1_4, etc.
    # The pattern looks for a letter (z, g, w, m, p) followed by a digit, then another digit.
    # E.g., z11, g12, m14, etc.
    # We want to replace it only when it's part of our specific keys to avoid breaking unrelated things.
    
    # We will target specific prefixes:
    # 1. techtree.zimmer.z11 -> techtree.zimmer.z1_1
    # 2. techtree.gastro.g11 -> techtree.gastro.g1_1
    # 3. techtree.wellness.w11 -> techtree.wellness.w1_1
    # 4. techtree.management.m11 -> techtree.management.m1_1
    # 5. techtree.prestige.p11 -> techtree.prestige.p1_1
    # 6. ui.techtree.feature.z11_speed -> ui.techtree.feature.z1_1_speed
    
    prefixes = [
        'techtree.zimmer.z', 'techtree.gastro.g', 'techtree.wellness.w', 
        'techtree.management.m', 'techtree.prestige.p',
        'ui.techtree.feature.z', 'ui.techtree.feature.g', 'ui.techtree.feature.w',
        'ui.techtree.feature.m', 'ui.techtree.feature.p'
    ]
    
    # Actually, a regex is safest: (techtree\.[a-z]+\.[zgwm] | ui\.techtree\.feature\.[zgwm])(\d)(\d)
    # Let's just do a manual replace for the specific known ones to be 100% safe.
    
    letters = ['z', 'g', 'w', 'm', 'p']
    for l in letters:
        for i in range(1, 3):
            for j in range(1, 10):
                old_str = f"{l}{i}{j}"
                new_str = f"{l}{i}_{j}"
                
                # Replace in techtree keys
                content = content.replace(f"techtree.zimmer.{old_str}", f"techtree.zimmer.{new_str}")
                content = content.replace(f"techtree.gastro.{old_str}", f"techtree.gastro.{new_str}")
                content = content.replace(f"techtree.wellness.{old_str}", f"techtree.wellness.{new_str}")
                content = content.replace(f"techtree.management.{old_str}", f"techtree.management.{new_str}")
                content = content.replace(f"techtree.prestige.{old_str}", f"techtree.prestige.{new_str}")
                
                # Replace in feature keys
                content = content.replace(f"ui.techtree.feature.{old_str}", f"ui.techtree.feature.{new_str}")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

replace_in_file('d:/game-dev/homasim-godot/translations/language.csv')
replace_in_file('d:/game-dev/homasim-godot/config/techtree.json')
replace_in_file('d:/game-dev/homasim-godot/autoload/StaffManager.gd')
# Also check GameState.gd or any other scripts just in case
replace_in_file('d:/game-dev/homasim-godot/autoload/GameState.gd')

print("Replacement complete.")
