"""Fetch only selected official CC0 runtime assets for the 32-game collection."""
import json,pathlib,runpy,sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from fetch_licensed_assets import pack
manifest_path=ROOT/'game/assets/licensed/sources.json'
if not manifest_path.exists(): runpy.run_path(str(ROOT/'scripts/fetch_licensed_assets.py'),run_name='__main__')
manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
selection={
 'top-down-tanks-remastered':['PNG/Default size/tank_'+c+'.png' for c in ['green','red','sand','blue']]+['PNG/Default size/'+n+'.png' for n in ['crateWood','sandbagBeige','treeGreen_small','bulletDark1']],
 'sports-pack':['PNG/Equipment/'+n+'.png' for n in ['ball_basket1','ball_bowling1','ball_soccer1','ball_tennis1','ball_golf','golf_club']],
 'tiny-dungeon':['Tilemap/tilemap.png'],
 'impact-sounds':['Audio/'+n+'.ogg' for n in ['impactPunch_medium_000','impactPunch_heavy_000','impactMetal_light_000','impactWood_medium_000']],
 'digital-audio':['Audio/'+n+'.ogg' for n in ['laser2','lowDown','highUp','powerUp2','threeTone1']]}
for name,members in selection.items():
    archive,record=pack(name)
    folder=ROOT/'game/assets/licensed'/name;folder.mkdir(exist_ok=True)
    for member in members: (folder/pathlib.Path(member).name).write_bytes(archive.read(member))
    license_member=next(n for n in archive.namelist() if n.lower().endswith('license.txt'))
    (folder/'LICENSE.txt').write_bytes(archive.read(license_member))
    manifest=[m for m in manifest if m['page']!=record['page']]+[record]
manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('EXPANSION_ASSETS_READY')
