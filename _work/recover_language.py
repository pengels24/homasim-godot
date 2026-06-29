import os

data = open('d:/game-dev/homasim-godot/translations/language.csv', 'rb').read()
out = bytearray()

i = 0
while i < len(data):
    if data[i:i+3] == b'\\xe2\\x82\\xac':
        i += 3
        if i < len(data):
            out.append(data[i])
            i += 1
    else:
        out.append(data[i])
        i += 1

with open('d:/game-dev/homasim-godot/translations/language_clean.csv', 'wb') as f:
    f.write(out)

print("Recovered file saved to language_clean.csv")
