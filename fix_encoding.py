import re, pathlib

EXTS = {'.html', '.js', '.css', '.json'}

def to_bytes(run):
    out = bytearray()
    for ch in run:
        try:
            out += ch.encode('cp1252')
        except UnicodeEncodeError:
            if ord(ch) < 256:
                out.append(ord(ch))   # bytes cp1252 leaves undefined (0x81, 0x8D...)
            else:
                raise
    return bytes(out)

def fix_run(m):
    run = m.group(0)
    try:
        return to_bytes(run).decode('utf-8')
    except (UnicodeEncodeError, UnicodeDecodeError):
        return run   # already-correct text is left alone

for p in pathlib.Path('.').rglob('*'):
    if p.suffix.lower() not in EXTS or 'node_modules' in p.parts:
        continue
    try:
        text = p.read_text(encoding='utf-8-sig')
    except UnicodeDecodeError:
        print('skipped (not UTF-8):', p)
        continue
    fixed = re.sub(r'[^\x00-\x7f]+', fix_run, text)
    if fixed != text:
        p.write_text(fixed, encoding='utf-8', newline='')
        print('fixed:', p)