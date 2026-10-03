"""Generate the public catalog from the same game IDs used by the app."""
from pathlib import Path
import json,re,html
ROOT=Path(__file__).resolve().parents[1]
games=json.loads((ROOT/'game/assets/catalog.json').read_text(encoding='utf-8'))
p=ROOT/'docs/index.html';s=p.read_text(encoding='utf-8')
s=s.replace('yedi mini oyun','32 mini oyun').replace('Yedi mini oyun','32 mini oyun').replace('Yedi farklı oyun, kısa turlar, bol rekabet.','32 oyun. Dövüş, tank, zıplama, spor ve klasikler.').replace('v1.1.0','v1.2.0')
s=s.replace('Küçük oyunlar.<br><em>Büyük rekabet.</em>','32 oyun.<br><em>Bir tur daha.</em>')
s=s.replace('4 RENK. TEK ARENA.','32 OYUN. 4 RENK.').replace('cep arena / kristal kapmaca','cep arena / tank düellosu').replace('src="assets/gameplay.jpg" alt="Kristal Kapmaca oyununda üç bot ve bir oyuncunun 3D arenası"','src="assets/game8.jpg" alt="Tank Düellosu: dört tank, sektiren mermiler ve siperler"')
s=re.sub(r'<div class="catalog-tools">.*?<span id="catalog-count"[^>]*>.*?</span></div>','',s,flags=re.S)
a=s.index('<div class="game-grid">');b=s.index('</section>',a)
filters='<div class="catalog-tools"><label>Oyun ara<input id="game-search" type="search" placeholder="Tank, golf, dövüş…"></label><div class="category-buttons" role="group" aria-label="Oyun kategorileri">'+''.join(f'<button type="button" data-category="{html.escape(c)}" aria-pressed="{str(c=="Tümü").lower()}">{html.escape(c)}</button>' for c in ['Tümü','Dövüş','Tank/Uzay','Zıplama','Spor','Klasik','Parti'])+'</div><span id="catalog-count" aria-live="polite">32 oyun</span></div>'
cards=[]
for i,g in enumerate(games):
    cards.append(f'<article class="game-card" data-category="{html.escape(g["category"])}" data-name="{html.escape(g["name"])}" style="--accent:#{g["color"]}"><img src="assets/game{i}.svg" alt="{html.escape(g["name"])} oyun ikonu" loading="lazy"><div class="card-copy"><span class="game-tag">{i+1:02} / {html.escape(g["category"].upper())}</span><h3>{html.escape(g["name"])}</h3><p>{html.escape(g["desc"])}</p><span class="duration">{int(g["duration"])} SANİYE <span>↗</span></span></div></article>')
s=s[:a]+filters+'<div class="game-grid">'+ '\n'.join(cards)+'</div>'+s[b:]
if 'id="oynanis"' not in s:
    marker='<section id="birlikte"'
    gallery='<section id="oynanis" class="section wrap"><div class="eyebrow">OYUNUN İÇİNDEN</div><h2>Her tur başka bir dünya.</h2><div class="preview-grid">'+''.join(f'<a href="assets/game{i}.jpg"><img src="assets/game{i}.jpg" alt="{html.escape(games[i]["name"])} gerçek oyun ekranı" loading="lazy"><span>{html.escape(games[i]["name"])}</span></a>' for i in [7,15,25])+'</div><p class="preview-note">Uygulamadan alınan gerçek oyun görüntüleri.</p></section>'
    s=s.replace(marker,gallery+marker)
s=s.replace('340 oyun kuralı ve 21 arayüz kontrolü geçti. Yedi oyunda dört süreç arasında LAN bağlantısı doğrulandı.','32 oyun tam tur testinden geçti. Kategori, arama, favoriler ve 32. oyuna gamepad ile ulaşma dahil 26 arayüz kontrolü geçti. Dört ayrı süreçle 32 oyunda LAN bağlantısı sınandı.')
controls='Ana hamle A / × / Boşluk / sol tık, ikinci hamle X / □ / E / sağ tıktır. Mobilde iki ayrı hamle düğmesi görünür. '
s=s.replace(controls,'')
s=s.replace('Tuş gösterimi, ölü bölge',controls+'Tuş gösterimi, ölü bölge')
s=s.replace('</body>', '<script src="catalog.js"></script></body>') if 'src="catalog.js"' not in s else s
p.write_text(s,encoding='utf-8')
print('SITE_32_GAME_CATALOG_READY')
