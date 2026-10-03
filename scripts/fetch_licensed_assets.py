"""Download selected CC0 Kenney assets and the MIT Godot Bomber reference.

Only the listed packs from their official publishers are used. No full archive is
published; the selected runtime files and original license notices are retained.
"""
import hashlib, io, json, pathlib, re, urllib.request, zipfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
CACHE = ROOT / 'tools' / 'licensed'
CACHE.mkdir(parents=True, exist_ok=True)

def get(url):
    req = urllib.request.Request(url, headers={'User-Agent':'CepArena/1.1'})
    return urllib.request.urlopen(req, timeout=90).read()

def pack(name):
    page = 'https://kenney.nl/assets/' + name
    html = get(page).decode()
    url = re.search(r"href=['\"]([^'\"]+\.zip)['\"]", html).group(1)
    dest = CACHE / (name + '.zip')
    if not dest.exists(): dest.write_bytes(get(url))
    archive = zipfile.ZipFile(dest)
    if archive.testzip(): raise RuntimeError('Corrupt licensed archive')
    print(name, len(dest.read_bytes()), archive.namelist()[:12])
    return archive, {'publisher':'Kenney','page':page,'download':url,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'license':'CC0 1.0'}

if __name__ == '__main__':
    manifest = []
    assets = ROOT / 'game' / 'assets' / 'licensed'
    assets.mkdir(parents=True, exist_ok=True)
    selection = {
      'mini-arena': ['Models/GLB format/'+n+'.glb' for n in ['column','column-damaged','tree','banner','trophy','character-soldier']] + ['Models/GLB format/Textures/colormap.png'],
      'space-shooter-remastered': ['PNG/playerShip1_'+c+'.png' for c in ['green','red','blue','orange']] + ['PNG/Meteors/meteorBrown_big1.png','PNG/Meteors/meteorBrown_med1.png','PNG/Effects/fire00.png','PNG/Effects/shield1.png'],
      'interface-sounds': ['Audio/'+n+'.ogg' for n in ['click_001','select_001','confirmation_001','back_001']]
    }
    for name in selection:
        archive, record = pack(name)
        manifest.append(record)
        (CACHE / (name + '-files.txt')).write_text('\n'.join(archive.namelist()), encoding='utf-8')
        folder = assets / name
        folder.mkdir(exist_ok=True)
        for member in selection[name]:
            if member not in archive.namelist(): raise RuntimeError('Missing selected asset: '+member)
            relative = 'Textures/'+pathlib.Path(member).name if '/Textures/' in member else pathlib.Path(member).name
            target = folder / relative
            target.parent.mkdir(exist_ok=True)
            target.write_bytes(archive.read(member))
        license_member = next(n for n in archive.namelist() if n.lower().endswith('license.txt'))
        (folder/'LICENSE.txt').write_bytes(archive.read(license_member))
    revision = '3e08537616661a5883831628decab4c526260289'
    base = 'https://raw.githubusercontent.com/godotengine/godot-demo-projects/'+revision+'/'
    for name in ['LICENSE.md','networking/multiplayer_bomber/bomb.gd','networking/multiplayer_bomber/player.gd','networking/multiplayer_bomber/README.md','networking/multiplayer_bomber/charwalk.png','networking/multiplayer_bomber/brickfloor.png','networking/multiplayer_bomber/explosion.png']:
        (CACHE / pathlib.Path(name).name).write_bytes(get(base+name))
    bomber = assets / 'godot-bomber'
    bomber.mkdir(exist_ok=True)
    for name in ['LICENSE.md','charwalk.png','brickfloor.png','explosion.png']:
        (bomber/name).write_bytes((CACHE/name).read_bytes())
    manifest.append({'publisher':'Godot Engine contributors','page':'https://github.com/godotengine/godot-demo-projects/tree/'+revision+'/networking/multiplayer_bomber','revision':revision,'license':'MIT','adaptation':'Authoritative grid bomber rules, original character and explosion graphics','sha256':{n:hashlib.sha256((CACHE/n).read_bytes()).hexdigest() for n in ['bomb.gd','player.gd','charwalk.png','explosion.png','LICENSE.md']}})
    (assets / 'sources.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    (CACHE / 'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
