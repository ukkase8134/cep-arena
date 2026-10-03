import math, pathlib, struct, wave
ROOT=pathlib.Path(__file__).resolve().parents[1]
ASSETS=ROOT/'game'/'assets'
ASSETS.mkdir(parents=True,exist_ok=True)
colors=['#80f5cd','#ff846b','#b6a1ff','#78caff']
def actor(x,y,c):
    return f'<ellipse cx="{x}" cy="{y+24}" rx="18" ry="6" fill="#000" opacity=".2"/><rect x="{x-12}" y="{y-4}" width="24" height="29" rx="10" fill="{c}"/><circle cx="{x}" cy="{y-8}" r="15" fill="{c}"/><circle cx="{x-5}" cy="{y-9}" r="2" fill="#111a31"/><circle cx="{x+5}" cy="{y-9}" r="2" fill="#111a31"/>'
for game in range(6):
    svg='<svg xmlns="http://www.w3.org/2000/svg" width="440" height="220" viewBox="0 0 440 220"><rect width="440" height="220" rx="16" fill="#16243e"/>'
    if game in [0,1,2]:
        svg+='<path d="M220 20 399 110 220 201 41 110Z" fill="#243a54"/><path d="m41 110 179 91 179-91v13l-179 91-179-91Z" fill="#0d182c"/>'
        if game==0:
            for x,y in [(175,71),(260,74),(305,114),(210,140),(133,118),(233,103)]: svg+=f'<path d="m{x} {y-12} 9 12-9 14-9-14Z" fill="#80f5cd"/><path d="m{x} {y-12} 0 26-9-14Z" fill="#48bfa0"/>'
        elif game==1:
            for row in range(5):
                for col in range(5):
                    x=220+(col-row)*29; y=44+(col+row)*15
                    svg+=f'<path d="m{x} {y} 27 14-27 14-27-14Z" fill="{colors[(row+col)%4]}" opacity=".85"/>'
        else:
            svg+='<ellipse cx="220" cy="115" rx="133" ry="67" fill="#29334b" stroke="#ffcf70" stroke-width="3"/><path d="m112 91 215 48" stroke="#ff846b" stroke-width="10" stroke-linecap="round"/><ellipse cx="220" cy="114" rx="12" ry="7" fill="#ffcf70"/>'
        for i,(x,y) in enumerate([(145,107),(274,102),(225,158),(240,62)]): svg+=actor(x,y,colors[i])
    elif game==3:
        svg+='<circle cx="220" cy="110" r="88" fill="#0c172c" stroke="#3a5572" stroke-width="3"/><circle cx="220" cy="110" r="27" fill="none" stroke="#294766" stroke-width="2"/><path d="M132 110h176M220 22v176" stroke="#294766"/>'
        for i,(x,y) in enumerate([(220,49),(280,110),(220,171),(160,110)]): svg+=f'<circle cx="{x}" cy="{y}" r="16" fill="{colors[i]}"/><circle cx="{x}" cy="{y}" r="10" fill="none" stroke="#fff" stroke-width="2"/>'
        svg+='<circle cx="238" cy="117" r="8" fill="#fff"/><path d="m232 120-32 18" stroke="#78caff" opacity=".4" stroke-width="4"/>'
    elif game==4:
        for i in range(4):
            y=36+i*48
            svg+=f'<path d="M35 {y}h370" stroke="#2a3c57" stroke-width="30" stroke-linecap="round"/><path d="M45 {y}h350" stroke="#53718c" stroke-dasharray="16 24" opacity=".35"/>'
            x=100+i*36
            svg+=f'<path d="m{x+28} {y} -38-13 8 13-8 13Z" fill="{colors[i]}"/><path d="m{x-12} {y-5}-23 5 23 5Z" fill="#ffcf70"/><rect x="{300-i*17}" y="{y-12}" width="12" height="24" rx="4" fill="#ff846b"/>'
    else:
        for x,y in [(35,36),(61,121),(171,26),(300,48),(385,158),(284,198)]: svg+=f'<circle cx="{x}" cy="{y}" r="2" fill="#9ba9cd"/>'
        for i,(x,y) in enumerate([(129,77),(283,79),(285,160),(156,159)]):
            svg+=f'<path d="m{x} {y-17} -13 29 13-6 13 6Z" fill="{colors[i]}"/>'
        for x,y in [(80,42),(225,138),(358,82)]: svg+=f'<path d="m{x-27} {y-22} 27 22" stroke="#ff846b" stroke-width="7" opacity=".3"/><circle cx="{x}" cy="{y}" r="10" fill="#ff846b"/><circle cx="{x-2}" cy="{y-2}" r="4" fill="#ffcf70"/>'
    svg+='</svg>'
    (ASSETS/f'game{game}.svg').write_text(svg,encoding='utf-8')
for name,freq,duration in [('tap',540,.09),('score',880,.14),('finish',660,.5)]:
    with wave.open(str(ASSETS/f'{name}.wav'),'wb') as wav:
        rate=22050; wav.setparams((1,2,rate,0,'NONE','not compressed'))
        frames=[]
        for i in range(int(rate*duration)):
            t=i/rate
            f=freq*(1+(int(t/.12)%3)*.25) if name=='finish' else freq
            envelope=min(1,t/.008)*max(0,1-t/duration)**2
            frames.append(struct.pack('<h',int(math.sin(2*math.pi*f*t)*envelope*6000)))
        wav.writeframes(b''.join(frames))
print('ASSETS_READY')
