'use strict';
(async () => {
  const repo = 'ukkase8134/cep-arena';
  try {
    const response = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {signal: AbortSignal.timeout(8000)});
    if (!response.ok) return;
    const release = await response.json();
    document.getElementById('release-status').textContent = `Güncel sürüm · ${release.tag_name}`;
    for (const [name, button, detail] of [['CepArena-Android.apk', 'apk-download', 'apk-size'], ['CepArena-Windows.exe', 'exe-download', 'exe-size']]) {
      const asset = release.assets.find(item => item.name === name);
      if (!asset) continue;
      const url = new URL(asset.browser_download_url);
      if (url.origin !== 'https://github.com' || !url.pathname.startsWith(`/${repo}/releases/download/`)) continue;
      document.getElementById(button).href = url.href;
      document.getElementById(detail).textContent = `${(asset.size / 1048576).toFixed(1)} MB · ${name.endsWith('.apk') ? 'İmzalı APK' : 'Tek dosya, kurulum gerekmez'}`;
    }
  } catch { /* The static latest-release links remain usable without the API. */ }
})();
