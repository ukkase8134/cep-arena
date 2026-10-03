"""Keep the public game table aligned with the app's stable catalog IDs."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
games = json.loads((ROOT / 'game/assets/catalog.json').read_text(encoding='utf-8'))
rows = '\n'.join(f'| {i+1} | {g["name"]} | {g["category"]} | {g["action"]} | {g["secondary"] or "—"} | {int(g["duration"])} sn |' for i, g in enumerate(games))
readme = '''# Cep Arena 1.2.0

Android ve Windows için 2–4 oyunculu **32 mini oyun**. Botlarla, aynı cihazda bağımsız gamepad'lerle veya aynı LAN'da ayrı cihazlarla oynanabilir.

[İndirme sayfası](https://ukkase8134.github.io/cep-arena/) · [APK](https://github.com/ukkase8134/cep-arena/releases/latest/download/CepArena-Android.apk) · [EXE](https://github.com/ukkase8134/cep-arena/releases/latest/download/CepArena-Windows.exe) · [Doğrulama](QA.md)

## Kontroller

- Menü: sol çubuk / D-pad, A / × ile seçim, B / ○ ile geri. Kategori, arama, favoriler ve açılır ayarlar kontrolcüyle kullanılabilir.
- Oyun: WASD / oklar veya sol çubuk. Ana hamle A / × / RB / R1 / Boşluk / sol tık. İkinci hamle X / □ / LB / L1 / E / Shift / sağ tık.
- Android: bağımsız joystick ve hamle düğmeleri; ikinci hamlesi bulunan oyunlarda ikinci düğme. USB / Bluetooth gamepad desteği.
- Aynı PC: bir klavye/mouse oyuncusu ve her gamepad ayrı oyuncu. İki gamepad + bir klavye/mouse ile üç kişi oynayabilir.
- Oyundaki Ana menü, B / ○, Start veya Esc menüye döner. Ana menüdeki Çık uygulamayı kapatır.
- Titreşim oyun olaylarına bağlıdır. Bekleme sırasında periyodik sinyal gönderilmez.

Dönen Çember 90 saniyedir. Havada kalma 0,88 sn, yeniden zıplama aralığı 0,94 sn; basılı tutmak yeniden zıplatır. Platform oyunlarında 160 ms giriş tamponu, 120 ms kenar toleransı, kısa/uzun basış ve gerçek düşey hız kullanılır.

## Oyunlar

| No | Oyun | Kategori | Ana hamle | İkinci hamle | Tur |
|---|---|---|---|---|---|
''' + rows + '''

Üç turluk turnuva üç farklı oyun seçer. Botların üç zorluk seviyesi vardır. Oyunlar farklı kurallar kullanır: kombo/gard, mermi sektirme, rüzgâr/yerçekimi, platform iniş/çıkışı, top fiziği, hücre/kuyruk çarpışması ve yön dizileri.

## LAN ve Radmin

Bir oyuncu LAN odası kurar, diğerleri odada gösterilen yerel veya Radmin IP adresine katılır. UDP 28742, aynı uygulama sürümü ve ağ erişimi gerekir. Android aynı Wi-Fi/LAN üzerinden katılır; Radmin PC içindir. GitHub kodu, sürümleri ve indirme sayfasını barındırır. Maç trafiği oda sahibine gider.

Oda sahibi 60 Hz oyun kurallarını yürütür; istemciler sınırlandırılmış hareket/hamle gönderir, puan veya pozisyon gönderemez. Sıkıştırılmış durumlar 20 Hz paylaşılır. Cihaz ayrılması ve eski girdilerin sıfırlanması ele alınır.

## Geliştirme ve paketleme

Godot 4.7.2 stable. Android minimum API 24; ARMv7, ARM64, x86_64. Windows 64 bit, OpenGL 3.3.

```powershell
python scripts/fetch_tools.py
python scripts/fetch_licensed_assets.py
python scripts/fetch_expansion_assets.py
python scripts/create_expansion_assets.py
python scripts/verify.py --captures
powershell -File scripts/build.ps1
python scripts/prepare_site.py
python scripts/prepare_catalog_site.py
```

`artifacts/` EXE, APK ve SHA256SUMS.txt içerir. Android imza anahtarı `.secrets/` altında korunur ve Git'e eklenmez. Windows XInput motor köprüsü EXE'ye gömülür. [Kaynak ve lisanslar](THIRD-PARTY.md).

Fiziksel Android, PS4, aynı anda iki gamepad ve gerçek dört PC/Radmin doğrulaması henüz yapılmadı. Otomatik sonuçlar fiziksel cihaz deneyiminin yerine geçmez.
'''
(ROOT / 'README.md').write_text(readme, encoding='utf-8')
