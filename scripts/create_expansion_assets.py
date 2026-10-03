"""Original vector identity and game illustrations; all shapes are editable SVG."""
from pathlib import Path
import json,shutil,math
ROOT=Path(__file__).resolve().parents[1];A=ROOT/'game/assets';D=ROOT/'docs/assets'
games=json.loads((A/'catalog.json').read_text(encoding='utf-8'))
(ROOT/'game/scripts/catalog.gd').write_text('extends RefCounted\n## Shared game IDs are stable across saves, network messages and the website.\nconst GAMES = '+json.dumps(games,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
icons=[
'<path d="m0-46 35 43L0 47l-35-50Z" fill="C"/><path d="m0-46 0 93-35-50Z" fill="#fff" opacity=".25"/>',
'<path d="m-48-12 28-15 28 15-28 15Zm42 0 28-15 28 15-28 15Zm-21 24 28-15 28 15-28 15Z" fill="C"/>',
'<ellipse rx="50" ry="28" fill="none" stroke="C" stroke-width="8"/><path d="m-53-15 106 30" stroke="#ff846b" stroke-width="11" stroke-linecap="round"/><circle cy="-30" r="15" fill="#fff"/>',
'<circle r="44" fill="none" stroke="C" stroke-width="7"/><circle cx="-18" cy="8" r="16" fill="C"/><circle cx="26" cy="-19" r="8" fill="#fff"/>',
'<path d="m0-50-33 79 33-13 33 13Z" fill="C"/><path d="m-13 32 13 24 13-24Z" fill="#ffcf70"/><path d="m0-24-8 22h16Z" fill="#203047"/>',
'<circle cx="25" cy="16" r="30" fill="C"/><path d="m-40-42 30 25m-45 10 26 14m-9-55 15 22" stroke="#ffcf70" stroke-width="9" stroke-linecap="round"/>',
'<circle cy="12" r="34" fill="#28364b" stroke="C" stroke-width="5"/><path d="M0-22q0-29 21-22" fill="none" stroke="#fff" stroke-width="6"/><path d="m21-44 7-16 7 16 16 7-16 7-7 16-7-16-16-7Z" fill="#ffcf70"/>',
'<path d="M-40 18v-32q0-20 18-20h30q28 0 28 20v34l-23 24h-31Z" fill="C"/><path d="M-40-3h24q18 0 18 21v20" fill="none" stroke="#0b1428" stroke-width="5"/><path d="M-24-35v20m16-20v20m16-20v20" stroke="#fff" opacity=".5" stroke-width="4"/>',
'<rect x="-44" y="-38" width="21" height="83" rx="10" fill="#263851"/><rect x="23" y="-38" width="21" height="83" rx="10" fill="#263851"/><rect x="-32" y="-29" width="64" height="64" rx="12" fill="C"/><circle r="19" fill="#fff" opacity=".25"/><path d="M0 0v-51" stroke="C" stroke-width="14" stroke-linecap="round"/>',
'<path d="m-6 12-24-24 55-46 10 10Z" fill="C"/><path d="m-36-5 38 38" stroke="#ffcf70" stroke-width="10" stroke-linecap="round"/><path d="m-19 13-22 22" stroke="#fff" stroke-width="10"/>',
'<ellipse rx="49" ry="28" fill="none" stroke="C" stroke-width="7"/><circle cy="-26" r="21" fill="#fff"/><path d="M-26 10q26-23 52 0v28h-52Z" fill="C"/>',
'<path d="m-42 20 35-28 36 28" fill="none" stroke="C" stroke-width="12"/><rect x="-38" y="16" width="76" height="30" rx="13" fill="C"/><path d="M-10 9 30-31" stroke="#fff" stroke-width="14"/><path d="m31-48 4-13 4 13 13 4-13 4-4 13-4-13-13-4Z" fill="#ffcf70"/>',
'<path d="M-21 44v-88" stroke="#fff" stroke-width="7"/><path d="m-17-44 61 18-61 18Z" fill="C"/><ellipse cx="-21" cy="45" rx="29" ry="7" fill="C" opacity=".4"/>',
'<path d="m-43-23 25 21L0-41 18-2l25-21-8 61h-70Z" fill="C"/><circle cy="8" r="8" fill="#fff"/><path d="M-28 26h56" stroke="#0b1428" stroke-width="6"/>',
'<path d="m0-49-21 49-30 33 51-13 51 13-30-33Z" fill="C"/><path d="M0-18v35" stroke="#fff" stroke-width="7"/><path d="M-40-49v22m80-15v22" stroke="#ff846b" stroke-width="7"/>',
'<rect x="-46" y="28" width="37" height="13" rx="5" fill="C"/><rect x="-4" y="-1" width="37" height="13" rx="5" fill="#b6a1ff"/><rect x="21" y="-32" width="37" height="13" rx="5" fill="#ffcf70"/><path d="M-26 14q0-48 36-54" fill="none" stroke="#fff" stroke-width="5" stroke-dasharray="8 8"/><circle cx="-27" cy="10" r="11" fill="#fff"/>',
'<path d="M-52 33h104" stroke="C" stroke-width="9"/><path d="M12 33V-7h22v40" fill="#ffcf70"/><circle cx="-15" cy="-38" r="12" fill="#fff"/><path d="m-18-19 17 12 12-12m-29 0-20 25m21-10-10 22" fill="none" stroke="C" stroke-width="11" stroke-linecap="round"/>',
'<path d="M-51 30q13-29 26 0t26 0 26 0 26 0v20h-104Z" fill="#ff846b"/><rect x="-29" y="-5" width="58" height="13" rx="4" fill="C"/><path d="m-12-20 12-24 12 24" fill="none" stroke="#fff" stroke-width="7"/>',
'<path d="M-49-18q0 84 98 0" fill="none" stroke="C" stroke-width="8"/><path d="M-49-18v-24m98 24v-24" stroke="#fff" stroke-width="13" stroke-linecap="round"/><circle cy="-20" r="15" fill="#fff"/>',
'<ellipse cy="14" rx="39" ry="27" fill="C"/><circle cx="-22" cy="-14" r="18" fill="C"/><circle cx="22" cy="-14" r="18" fill="C"/><circle cx="-22" cy="-16" r="8" fill="#fff"/><circle cx="22" cy="-16" r="8" fill="#fff"/><circle cx="-22" cy="-16" r="4" fill="#15213c"/><circle cx="22" cy="-16" r="4" fill="#15213c"/><path d="M-13 17q13 11 26 0" fill="none" stroke="#15213c" stroke-width="4"/>',
'<ellipse cx="-6" cy="-6" rx="32" ry="38" transform="rotate(-30)" fill="C"/><path d="m-2 27 23 32" stroke="#ffcf70" stroke-width="13"/><circle cx="42" cy="-29" r="11" fill="#fff"/>',
'<circle r="43" fill="#fff"/><path d="m0-20 20 15-8 24h-24l-8-24Z" fill="#203047"/><path d="m-40-17 20 12m60-12L20-5M-12 19l-8 23m32-23 8 23M0-20v-23" stroke="#203047" stroke-width="7"/>',
'<circle r="43" fill="C"/><path d="M-42 0h84M0-42v84M-34-26q50 16 56 61M34-26q-50 16-56 61" fill="none" stroke="#203047" stroke-width="5"/>',
'<path d="M-12-45q-14 9-6 30l-12 46q-1 15 30 15t30-15L18-15q8-21-6-30Z" fill="#fff"/><path d="M-19-10h38M-21 2h42" stroke="C" stroke-width="7"/><circle cx="-36" cy="28" r="20" fill="#b6a1ff"/>',
'<path d="M13 44v-89" stroke="#fff" stroke-width="6"/><path d="m17-45 37 15-37 15Z" fill="C"/><ellipse cx="11" cy="43" rx="32" ry="8" fill="#0b1428"/><circle cx="-27" cy="18" r="13" fill="#fff"/>',
'<path d="M-39 26h30V-4h28v-30h28" fill="none" stroke="C" stroke-width="23" stroke-linecap="round" stroke-linejoin="round"/><circle cx="40" cy="-38" r="3" fill="#16243e"/><path d="m47-27 12 8" stroke="#ff846b" stroke-width="4"/>',
'<path d="M-46-33h26m7 0h26m7 0h26M-46-14h26m7 0h26m7 0h26" stroke="C" stroke-width="13"/><path d="M-31 41h62" stroke="#fff" stroke-width="11" stroke-linecap="round"/><circle cx="7" cy="14" r="11" fill="#ffcf70"/>',
'<path d="m-37-27 31-18 37 14 13 36-23 35-40-6-21-31Z" fill="C"/><circle cx="-9" cy="-7" r="11" fill="#203047" opacity=".4"/><circle cx="20" cy="18" r="8" fill="#203047" opacity=".4"/>',
'<path d="M-43 0q0-38 43-38T43 0v35h-86Z" fill="C"/><path d="M-43 3h86" stroke="#203047" stroke-width="6"/><rect x="-8" y="-3" width="16" height="23" rx="4" fill="#fff"/>',
'<rect x="-42" y="-40" width="37" height="37" rx="8" fill="C"/><rect x="5" y="-40" width="37" height="37" rx="8" fill="#ffcf70"/><rect x="-42" y="5" width="37" height="37" rx="8" fill="#78caff"/><rect x="5" y="5" width="37" height="37" rx="8" fill="#b6a1ff"/>',
'<path d="m10-49-41 55h26l-8 43L31-9H5Z" fill="C"/>',
'<path d="M-40 30q-21-16-2-28l32-22 43 32-25 36Z" fill="C"/><path d="m-8-19 15-22 42 33-15 21Z" fill="#fff"/><path d="m44-39 9 11-9 11-9-11Z" fill="C"/>'
]
for i,g in enumerate(games):
    color='#'+g['color']; pict=icons[i].replace('C',color)
    # Composition: a central game emblem, depth, supporting objects, four player chips.
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="440" height="220" viewBox="0 0 440 220"><defs><linearGradient id="bg" x2="1" y2="1"><stop stop-color="#25304e"/><stop offset="1" stop-color="#111a30"/></linearGradient></defs><rect width="440" height="220" rx="22" fill="url(#bg)"/><path d="M0 183 440 55v165H0Z" fill="{color}" opacity=".035"/><circle cx="220" cy="110" r="86" fill="{color}" opacity=".07"/><circle cx="220" cy="110" r="67" fill="none" stroke="{color}" opacity=".2" stroke-dasharray="5 10"/><ellipse cx="220" cy="173" rx="58" ry="11" fill="#000" opacity=".2"/><g transform="translate(220 107)">{pict}</g>'
    for n,c in enumerate(['#80f5cd','#ff846b','#b6a1ff','#78caff']):
        x=[63,375,77,363][n];y=[60,153,169,49][n]
        svg+=f'<g transform="translate({x} {y}) rotate({[-14,9,7,-10][n]})"><rect x="-17" y="-13" width="34" height="27" rx="11" fill="{c}"/><path d="M-6-3v7m12-7v7" stroke="#172238" stroke-width="3" stroke-linecap="round"/></g>'
    svg+='</svg>'
    (A/f'game{i}.svg').write_text(svg);shutil.copy2(A/f'game{i}.svg',D/f'game{i}.svg')
    (A/f'badge{i}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="-60 -60 120 120">{pict}</svg>')
brand='<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><defs><linearGradient id="b" x2="1" y2="1"><stop stop-color="#253451"/><stop offset="1" stop-color="#0e1729"/></linearGradient></defs><rect width="512" height="512" rx="124" fill="url(#b)"/><path d="m98 300 56-151 103-37 101 37 56 151-66 67-93-32-92 32Z" fill="#80f5cd"/><path d="m164 155 93-31 93 31-26 43H190Z" fill="#fff" opacity=".45"/><rect x="172" y="239" width="71" height="20" rx="8" fill="#17243a"/><rect x="197" y="214" width="20" height="71" rx="8" fill="#17243a"/><circle cx="316" cy="223" r="16" fill="#b6a1ff"/><circle cx="354" cy="256" r="16" fill="#ff846b"/><path d="m244 317 13-34 13 34Z" fill="#ffcf70"/><path d="m408 86 12 25 28 4-20 20 5 28-25-13-25 13 5-28-20-20 28-4Z" fill="#ffcf70"/></svg>'
(A/'icon.svg').write_text(brand);shutil.copy2(A/'icon.svg',D/'icon.svg')
for name,path in {'settings':'M-35 0h70M0-35v70M-25-25l50 50M25-25l-50 50','exit':'M-35-30v60h25M-12 0h48M18-18 36 0 18 18','lan':'M-32-28h64v33h-64ZM0 5v20M-35 35v-10h70v10','pad':'M-35 28q-20-45 0-52h70q20 7 0 52l-16-13h-38ZM-23-9v19M-32 0h19M18-4h1M29 7h1','star':'m0-36 11 23 25 4-18 18 4 25-22-12-22 12 4-25-18-18 25-4Z','back':'M35 0h-70M-12-23-35 0-12 23'}.items():
    (A/f'ui-{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="-48 -48 96 96"><path d="{path}" fill="none" stroke="#f4f6ff" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/></svg>')
print('32_ILLUSTRATIONS_32_BADGES_BRAND_READY')
