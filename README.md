# Cep Arena 1.2.0

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
| 1 | Kristal Kapmaca | Parti | Hızlan | — | 60 sn |
| 2 | Renk Adası | Parti | Atıl | — | 75 sn |
| 3 | Dönen Çember | Zıplama | Zıpla | — | 90 sn |
| 4 | Neon Hokey | Spor | Vur | — | 75 sn |
| 5 | Roket Ralli | Parti | Turbo | — | 75 sn |
| 6 | Meteor Yağmuru | Tank/Uzay | Kalkan | — | 75 sn |
| 7 | Bomba Arenası | Klasik | Bomba | — | 90 sn |
| 8 | Ring Kavgası | Dövüş | Yumruk | Gard | 90 sn |
| 9 | Tank Düellosu | Tank/Uzay | Ateş | Kalkan | 100 sn |
| 10 | Kılıç Meydanı | Dövüş | Savur | Par savuştur | 90 sn |
| 11 | Sumo Çemberi | Dövüş | İt | Sağlam dur | 90 sn |
| 12 | Tank Topçusu | Tank/Uzay | Şarj / Ateş | Yön değiştir | 100 sn |
| 13 | Bayrak Baskını | Parti | Hızlan | Bayrağı bırak | 90 sn |
| 14 | Taç Kapışması | Parti | İt | Kalkan | 90 sn |
| 15 | Uzay Muharebesi | Tank/Uzay | Lazer | Atıl | 90 sn |
| 16 | Zıpla ve Yüksel | Zıplama | Zıpla | — | 100 sn |
| 17 | Engel Koşusu | Zıplama | Zıpla | Kay | 90 sn |
| 18 | Lav Yükseliyor | Zıplama | Zıpla | — | 100 sn |
| 19 | İp Atlama | Zıplama | Zıpla | — | 90 sn |
| 20 | Kurbağa Geçidi | Zıplama | Hızlı sıçra | — | 90 sn |
| 21 | Pinpon | Spor | Falso | — | 90 sn |
| 22 | Mini Futbol | Spor | Şut | Koş | 100 sn |
| 23 | Basket Atışı | Spor | Güç / Atış | — | 90 sn |
| 24 | Bowling | Spor | Güç / Atış | — | 100 sn |
| 25 | Mini Golf | Spor | Güç / Vuruş | — | 110 sn |
| 26 | Yılan Yarışı | Klasik | Hızlan | — | 90 sn |
| 27 | Blok Kırıcı | Klasik | Topu bırak | — | 100 sn |
| 28 | Asteroit Avcısı | Tank/Uzay | Ateş | Kalkan | 90 sn |
| 29 | Hazine Koşusu | Parti | Hızlan | Çal | 90 sn |
| 30 | Hafıza Karoları | Klasik | Onay | — | 100 sn |
| 31 | Tepki Yarışı | Klasik | Bas | — | 90 sn |
| 32 | Bölge Boyama | Parti | Boya dalgası | Kalkan | 100 sn |

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
