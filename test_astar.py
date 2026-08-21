import math

r1 = {'left': 1, 'top': 1, 'right': 4, 'bottom': 31}
r2 = {'left': 7, 'top': 7, 'right': 12, 'bottom': 31}
r3 = {'left': 7, 'top': 7, 'right': 22, 'bottom': 11}
r4 = {'left': 1, 'top': 1, 'right': 19, 'bottom': 4} # NavBlockerBackTop
blockers = [r1, r2, r3, r4]

def is_blocked(x, y):
    for b in blockers:
        b_w = b['right'] - b['left']
        b_h = b['bottom'] - b['top']
        p_lx = x - b['left']
        p_ly = y - b['top']
        if 0 <= p_lx < b_w and 0 <= p_ly < b_h:
            return True
    return False

print("Testing Y=6 points:")
for x_idx in range(8):
    x = x_idx * 4 + 2
    y = 6
    print(f"Point ({x}, {y}): Blocked? {is_blocked(x, y)}")
