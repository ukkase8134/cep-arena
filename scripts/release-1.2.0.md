# Cep Arena 1.2.0

Koleksiyon 7 oyundan 32 oyuna çıktı. Dövüş, tank, platform, spor ve klasik oyunlar farklı kurallarla aynı bot, gamepad, dokunmatik, LAN ve turnuva sistemine bağlandı.

- Ring Kavgası: üç vuruşluk kombo, gard, nakavt ve geri tepme. Kılıç Meydanı: menzil ve zamanlı savuşturma. Sumo Çemberi: küçülen ring ve rakibi dışarı itme.
- Tank Düellosu: siperler, sektiren mermiler, bağımsız kalkan beklemesi. Tank Topçusu: güç toplama/bırakma, namlu açısı, rüzgâr ve balistik atış. Uzay Muharebesi ve parçalanan kayalarla Asteroit Avcısı.
- Zıpla ve Yüksel, Engel Koşusu, Lav Yükseliyor, İp Atlama ve Kurbağa Geçidi. Giriş tamponu ve kenar toleransı; koşuda kayma, nehirde kütük üzerinde kalma.
- Pinpon, takım halinde Mini Futbol, Basket Atışı, Bowling ve üç parkurlu Mini Golf. Yılan Yarışı, Blok Kırıcı, Hafıza Karoları ve Tepki Yarışı.
- Bayrak Baskını, Taç Kapışması, Hazine Koşusu ve Bölge Boyama.
- Dönen Çember 45 → 90 saniye. Zıplama 0,55 → 0,88 saniye; tekrar beklemesi 2,3 → 0,94 saniye. Basılı tutarak yeniden zıplama ve başlangıç toleransı.
- Yeni logo, 32 oyun illüstrasyonu ve rozeti, arayüz ikonları, daha büyük 3D karakterler, kategori/arama/favoriler, oyuna özel saha ve efektler. Ayrı darbe, metal, lazer, zıplama ve başarı sesleri.
- Ana hamle A / × / Boşluk / sol tık; ikinci hamle X / □ / E / sağ tık. Mobilde bağımsız iki hamle düğmesi. Menüden ve oyundan geri dönme akışı korunur; ana menü Çık uygulamayı kapatır.
- Kenney CC0 varlıkları; Godot Bomber MIT örneği ve Rubik OFL. Lisanslar APK/EXE içinde, kaynaklar oyun içindeki lisans ekranında ve [kaynak dökümünde](https://github.com/ukkase8134/cep-arena/blob/codex/cep-arena/THIRD-PARTY.md).

**Doğrulama:** 1470 simülasyon, 1586 oyun mekaniği/tam tur/durum paketi ve 26 arayüz kontrolü geçti. 32 oyun tam süresiyle dört botla sınandı. Dört bağımsız ENet süreciyle 32 oyun bağlantısı ve menü + 32 oyun gerçek GPU'da render edildi. İmzalı APK ve tek dosyalı Windows EXE üretildi.

Fiziksel telefon, PS4, aynı anda iki gamepad ve gerçek dört PC/Radmin maç doğrulaması henüz yapılmadı. Android paketi önceki sürümle aynı anahtarla imzalanır. Windows EXE yayıncı sertifikası kullanmaz.

[İndir](https://ukkase8134.github.io/cep-arena/) · [Test ayrıntıları](https://github.com/ukkase8134/cep-arena/blob/codex/cep-arena/QA.md)
