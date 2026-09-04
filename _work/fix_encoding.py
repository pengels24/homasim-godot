#!/usr/bin/env python3
"""
Repariert doppelt-encodierte Changelog-Dateien und konvertiert alle
Changelog-Dateien nach UTF-8 (mit BOM für maximale Kompatibilität).
"""
import os
import glob

def fix_double_encoded(raw_bytes):
    """Versucht verschiedene Strategien um die korrekte Decodierung zu finden."""
    # Strategie 1: War Latin-1 die Originalencoding, dann als Latin-1 lesen
    # und die daraus entstehenden Bytes als UTF-8 nochmal dekodieren (mojibake fix)
    try:
        # Wenn die Bytes als latin-1 lesbar sind UND das Ergebnis valid UTF-8 ergibt
        as_latin1 = raw_bytes.decode('latin-1')
        # Prüfen ob das latin-1-String selbst wieder als latin-1-bytes zu UTF-8 wird
        re_encoded = as_latin1.encode('latin-1')
        return re_encoded.decode('utf-8')
    except (UnicodeDecodeError, UnicodeEncodeError):
        pass
    
    # Strategie 2: Direkt als UTF-8 (war vielleicht schon korrekt)
    try:
        return raw_bytes.decode('utf-8')
    except UnicodeDecodeError:
        pass
    
    # Strategie 3: cp1252
    try:
        return raw_bytes.decode('cp1252')
    except UnicodeDecodeError:
        pass
    
    # Fallback: latin-1 (verlustfrei)
    return raw_bytes.decode('latin-1', errors='replace')


def process_file(filepath):
    with open(filepath, 'rb') as f:
        raw = f.read()
    
    # BOM entfernen falls vorhanden
    if raw.startswith(b'\xef\xbb\xbf'):
        raw = raw[3:]
    
    # Prüfen ob schon valid UTF-8
    try:
        content = raw.decode('utf-8')
        # Prüfen ob es mojibake enthält (Zeichen die so nie im Deutschen vorkommen sollten)
        if '\xc3\x83' in content or '\xc2\xa2' in content or 'Ã©' in content or 'Ã¤' in content:
            print(f"  [MOJIBAKE] {os.path.basename(filepath)}: Repariere doppelt-encodierte Bytes...")
            content = fix_double_encoded(raw)
        else:
            # Schon OK
            return False, "bereits UTF-8"
    except UnicodeDecodeError:
        print(f"  [CONVERT] {os.path.basename(filepath)}: Konvertiere von anderem Encoding...")
        content = fix_double_encoded(raw)
    
    # Als sauberes UTF-8 schreiben
    with open(filepath, 'w', encoding='utf-8', newline='\r\n') as f:
        f.write(content)
    
    return True, "repariert"


if __name__ == "__main__":
    changelog_dir = "changelog"
    files = sorted(glob.glob(os.path.join(changelog_dir, "*.md")))
    
    print(f"Prüfe {len(files)} Changelog-Dateien...")
    fixed = 0
    for fp in files:
        changed, status = process_file(fp)
        if changed:
            print(f"  ✓ {os.path.basename(fp)}: {status}")
            fixed += 1
    
    print(f"\nFertig: {fixed} von {len(files)} Dateien repariert/konvertiert.")
    
    # Auch alpha_backlog.md und status_quo.md prüfen
    for extra in ["wiki/alpha_backlog.md", "wiki/status_quo.md", "_work/uebergabe.md"]:
        if os.path.exists(extra):
            changed, status = process_file(extra)
            if changed:
                print(f"  ✓ {extra}: {status}")
