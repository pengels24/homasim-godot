import os
os.system('git checkout translations/language.csv')
data = open('d:/game-dev/homasim-godot/translations/language.csv', 'rb').read()
euro = bytes([0xe2, 0x82, 0xac])
data = b''.join(data.split(euro))
data = data.replace(b'"currency.symbol","",""', b'"currency.symbol","' + euro + b'","' + euro + b'"')
open('d:/game-dev/homasim-godot/translations/language.csv', 'wb').write(data)
