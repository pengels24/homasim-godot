import re
with open(r'C:\Users\angel\AppData\Roaming\Godot\app_userdata\HO·MA·SIM\hotels\hotel_43.cfg', 'r', encoding='utf-8') as f:
    text = f.read()

# wir suchen nach allen "room_number"
for match in re.finditer(r'\{([^{}]*\"room_number\"\s*:\s*\"([^\"]+)\"[^{}]*)\}', text):
    block = match.group(1)
    rn = match.group(2)
    m_type = re.search(r'\"room_type_id\"\s*:\s*\"([^\"]+)\"', block)
    rt = m_type.group(1) if m_type else 'Unknown'
    m = re.search(r'\"acquired_traits\"\s*:\s*(.*?)(?:,|})', block)
    traits = m.group(1).strip() if m else 'NOT FOUND'
    print(f'{rn} ({rt}): {traits}')
