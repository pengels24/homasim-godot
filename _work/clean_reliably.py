import os

# 1. Read from Git so we start fresh from the corrupted version
os.system('git checkout translations/language.csv')

# 2. Read the corrupted data
data = open('d:/game-dev/homasim-godot/translations/language.csv', 'rb').read()

# 3. Strip the corrupted euro signs inserted everywhere
data = data.replace(b'\\xe2\\x82\\xac', b'')

# 4. We know currency.symbol was "€", so stripping all euros made it empty. Fix it manually.
data = data.replace(b'"currency.symbol","",""', b'"currency.symbol","\\xe2\\x82\\xac","\\xe2\\x82\\xac"')

# 5. Save the clean file
open('d:/game-dev/homasim-godot/translations/language.csv', 'wb').write(data)

print("Restored cleanly.")
