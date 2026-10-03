param([switch]$SkipVerify)
$ErrorActionPreference = 'Stop'
$arenaRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $arenaRoot
$arenaGodot = (Get-ChildItem -LiteralPath "$arenaRoot\tools\editor" -Filter '*console.exe' | Select-Object -First 1).FullName
if (-not $arenaGodot) { throw 'Run scripts/fetch_tools.py first.' }
New-Item -ItemType Directory -Force -Path artifacts,.secrets,game/native | Out-Null
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:winexe /optimize+ "/out:$arenaRoot\game\native\CepHaptics.exe" "$arenaRoot\scripts\native_haptics.cs"
if ($LASTEXITCODE -ne 0) { throw 'Windows XInput helper build failed.' }
$arenaJava = Split-Path -Parent (Get-Command java.exe).Source
$arenaSecretPath = Join-Path $arenaRoot '.secrets\signing.json'
if (-not (Test-Path -LiteralPath $arenaSecretPath)) {
    $arenaBytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($arenaBytes)
    $arenaPassword = [Convert]::ToBase64String($arenaBytes).Replace('+','A').Replace('/','B').Replace('=','C')
    @{password=$arenaPassword;alias='cep-arena'} | ConvertTo-Json | Set-Content -LiteralPath $arenaSecretPath -Encoding UTF8
}
$arenaSecret = Get-Content -LiteralPath $arenaSecretPath -Raw | ConvertFrom-Json
if (-not (Test-Path -LiteralPath "$arenaRoot\.secrets\cep-arena.keystore")) {
    $ErrorActionPreference = 'Continue'
    & "$arenaJava\keytool.exe" -genkeypair -keystore "$arenaRoot\.secrets\cep-arena.keystore" -storetype PKCS12 -storepass $arenaSecret.password -keypass $arenaSecret.password -alias cep-arena -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=Cep Arena, OU=Games, O=Cep Arena, L=Istanbul, C=TR' 2>&1 | Out-Null
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0) { throw 'Could not generate the release signing key.' }
}
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = "$arenaRoot\.secrets\cep-arena.keystore"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $arenaSecret.alias
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $arenaSecret.password
try {
    $ErrorActionPreference = 'Continue'
    & $arenaGodot --headless --path game --editor --import --quit *> artifacts/import.log
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    if (-not $SkipVerify) {
        & $arenaGodot --headless --path game --script tests/simulation_test.gd *> artifacts/tests.log
        if ($LASTEXITCODE -ne 0) { throw 'Simulation tests failed.' }
    }
    & $arenaGodot --headless --path game --export-release Windows "$arenaRoot/artifacts/CepArena-Windows.exe" *> artifacts/windows-build.log
    if ($LASTEXITCODE -ne 0) { throw 'Windows export failed. See artifacts/windows-build.log.' }
    & $arenaGodot --headless --path game --export-release Android "$arenaRoot/artifacts/CepArena-Android.apk" *> artifacts/android-build.log
    if ($LASTEXITCODE -ne 0) { throw 'Android export failed. See artifacts/android-build.log.' }
    $arenaHashes = Get-FileHash -Algorithm SHA256 -LiteralPath artifacts/CepArena-Windows.exe,artifacts/CepArena-Android.apk
    $arenaHashes | ForEach-Object { "$($_.Hash.ToLowerInvariant())  $(Split-Path -Leaf $_.Path)" } | Set-Content -LiteralPath artifacts/SHA256SUMS.txt -Encoding ASCII
    Get-Item -LiteralPath artifacts/CepArena-Windows.exe,artifacts/CepArena-Android.apk | Select-Object Name,Length
    Write-Output 'BUILD_RELEASE_OK'
} finally {
    $ErrorActionPreference = 'Stop'
    Remove-Item Env:\GODOT_ANDROID_KEYSTORE_RELEASE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:\GODOT_ANDROID_KEYSTORE_RELEASE_USER -ErrorAction SilentlyContinue
    Remove-Item Env:\GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
}
