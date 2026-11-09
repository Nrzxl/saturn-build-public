# SATURN Android: release assinada local (PowerShell 5.1+).
# NUNCA publica a keystore em GitHub Actions. Execute SOMENTE no PC de confianca.
[CmdletBinding()]
param(
  [string] $Keystore = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'SATURN_SIGNING\saturn-release.keystore'),
  [string] $Alias = 'saturn'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Need([string] $cmd) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "Dependencia ausente: $cmd. Instale antes de publicar."
  }
}
function Secret([string] $label) {
  $secure = Read-Host -Prompt $label -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}
function Certificate([string] $file, [string] $signer) {
  $result = & $signer verify --print-certs $file 2>&1
  if ($LASTEXITCODE -ne 0) { throw "Falha na validacao de assinatura: $file" }
  $match = [regex]::Match(($result | Out-String),
      '(?im)Signer #1 certificate SHA-256 digest:\s*([a-f0-9]{64})')
  if (-not $match.Success) { throw "Certificado ilegivel: $file" }
  return $match.Groups[1].Value.ToLowerInvariant()
}
Need flutter
Need gh
Need keytool
if (-not (Test-Path -LiteralPath $Keystore)) {
  throw "Chave original ausente em $Keystore. Nao gere outra!"
}
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pubspec = Get-Content -LiteralPath (Join-Path $root 'pubspec.yaml') -Raw
$ver = [regex]::Match($pubspec, '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+\d+')
if (-not $ver.Success) { throw 'Versao ausente no pubspec.' }
$version = $ver.Groups[1].Value
$repo = 'Nrzxl/saturn-downloads'
$feed = Invoke-RestMethod -UseBasicParsing -Uri ('https://raw.githubusercontent.com/Nrzxl/saturn-downloads/main/update.json?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
if (-not $feed.apk_url -or -not $feed.sha256 -or -not $feed.build) {
  throw 'Manifesto antigo incompleto. Abortado.'
}
$build = [int][Math]::Max(1009, [int]$feed.build + 1)
$tag = 'v' + $version + '-b' + $build
$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$toolsDir = Join-Path $sdk 'build-tools'
if (-not (Test-Path $toolsDir)) { throw 'Android SDK Build Tools nao instalado.' }
$tools = Get-ChildItem $toolsDir -Directory | Sort-Object Name -Descending |
  Where-Object { Test-Path (Join-Path $_.FullName 'apksigner.bat') } | Select-Object -First 1
if (-not $tools) { throw 'apksigner.bat ausente no SDK.' }
$signer = Join-Path $tools.FullName 'apksigner.bat'
$aapt = Join-Path $tools.FullName 'aapt.exe'
if (-not (Test-Path $aapt)) { throw 'aapt.exe ausente no SDK.' }
Write-Host ('SATURN {0}, novo build {1}' -f $version, $build) -ForegroundColor Cyan
Write-Host 'Use a senha da chave JA EXISTENTE. Nunca a envie a terceiros.'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('SATURN-' + [guid]::NewGuid().ToString('N'))
$localKey = Join-Path $root 'android\app\saturn-release.keystore'
if ([IO.Path]::GetFullPath($Keystore) -eq [IO.Path]::GetFullPath($localKey)) {
  throw 'A chave original esta dentro da pasta de build. Mova para um local seguro primeiro.'
}
if (Test-Path $localKey) {
  throw 'Uma keystore ja existe em android/app. Nao vou sobrescrever ou apagar.'
}
$copiedKey = $false
$patched = $false
$originalGradle = $null
$originalManifest = $null
$gradle = Join-Path $root 'android\app\build.gradle.kts'
$manifest = Join-Path $root 'android\app\src\main\AndroidManifest.xml'
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$pass = $null
try {
  $pass = Secret 'Senha da chave SATURN original'
  if ([string]::IsNullOrWhiteSpace($pass)) { throw 'Senha vazia.' }
  $env:SATURN_KEY_ALIAS = $Alias
  $env:SATURN_KEY_PASSWORD = $pass
  $env:SATURN_KEYSTORE_PASSWORD = $pass
  & gh auth status | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Use gh auth login para conectar sua conta GitHub.' }
  # Query successful release listing; a missing tag must not emit native
  # stderr that PowerShell 5.1 may promote to an exception.
  $listed = & gh release list --repo $repo --json tagName --limit 100
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao consultar releases existentes.' }
  if (@($listed | ConvertFrom-Json | Where-Object { $_.tagName -eq $tag }).Count -gt 0) {
    throw "Release $tag ja existe. Abortado sem sobrescrever."
  }

  # Compara SHA256 do APK anterior + certificado do APK anterior e novo.
  $old = Join-Path $temp 'SATURN-anterior.apk'
  Invoke-WebRequest -UseBasicParsing -Uri ([string]$feed.apk_url) -OutFile $old
  $verifiedHash = (Get-FileHash $old -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($verifiedHash -ne ([string]$feed.sha256).ToLowerInvariant()) {
    throw 'O APK atual nao corresponde ao manifesto. Nao publicar.'
  }
  $previousCert = Certificate $old $signer
  Push-Location $root
  try {
    # Use the same default com.example.saturn_app template as the private
    # release workflow, then replace it with com.nrzxl.saturn exactly once.
    & flutter create --platforms=android --project-name saturn_app .
    if ($LASTEXITCODE -ne 0) { throw 'Falhou flutter create.' }
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falhou flutter pub get.' }
    & flutter analyze lib
    if ($LASTEXITCODE -ne 0) { throw 'Falhou flutter analyze.' }
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Falhou flutter test.' }
    $originalGradle = Get-Content $gradle -Raw
    $text = $originalGradle
    $before = 'signingConfig = signingConfigs.getByName("debug")'
    $after = 'signingConfig = signingConfigs.getByName("saturnRelease")'
    $application = 'applicationId = "com.example.saturn_app"'
    if (-not $text.Contains($before) -or -not $text.Contains($application)) {
      throw 'Template Android diferente ou ja alterado; nao arriscarei a chave.'
    }
    $config = @'
    signingConfigs {
        create("saturnRelease") {
            keyAlias = System.getenv("SATURN_KEY_ALIAS")
            keyPassword = System.getenv("SATURN_KEY_PASSWORD")
            storeFile = file("saturn-release.keystore")
            storePassword = System.getenv("SATURN_KEYSTORE_PASSWORD")
        }
    }
'@
    if ($text.Split(@('    buildTypes {'), [StringSplitOptions]::None).Count -ne 2) {
      throw 'Mais de um bloco buildTypes ou template inesperado.'
    }
    $text = $text.Replace('    buildTypes {', $config + '    buildTypes {')
    $text = $text.Replace($before, $after)
    $text = $text.Replace($application, 'applicationId = "com.nrzxl.saturn"')
    $patched = $true
    [IO.File]::WriteAllText($gradle, $text, (New-Object Text.UTF8Encoding($false)))
    $originalManifest = Get-Content $manifest -Raw
    $xml = $originalManifest.Replace('android:label="saturn_app"', 'android:label="SATURN"')
    if (-not $xml.Contains('android.permission.INTERNET')) {
      $xml = $xml.Replace('    <application', '    <uses-permission android:name="android.permission.INTERNET" />' + [Environment]::NewLine + '    <application')
    }
    [IO.File]::WriteAllText($manifest, $xml, (New-Object Text.UTF8Encoding($false)))
    Copy-Item $Keystore $localKey -Force
    $copiedKey = $true
    & flutter build apk --release --build-name $version --build-number $build
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar APK assinado.' }
  } finally { Pop-Location }
  $apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
  if (-not (Test-Path $apk)) { throw 'APK release nao encontrado.' }
  $badging = & $aapt dump badging $apk 2>&1 | Out-String
  if ($badging -notmatch "package: name='com.nrzxl.saturn'") {
    throw 'ApplicationId inesperado. Nao publicar.'
  }
  $newCert = Certificate $apk $signer
  if ($newCert -ne $previousCert) {
    throw 'O certificado NAO coincide com a versao antiga. Abortado!'
  }
  $sha = (Get-FileHash $apk -Algorithm SHA256).Hash.ToLowerInvariant()
  $outApk = Join-Path $temp 'SATURN.apk'
  Copy-Item $apk $outApk
  & gh release create $tag $outApk --repo $repo --title ("SATURN " + $version + " build " + $build) --notes 'Atualizacao assinada preservando o aplicativo instalado.'
  if ($LASTEXITCODE -ne 0) { throw 'Falha no upload da release.' }
  $url = 'https://github.com/' + $repo + '/releases/download/' + $tag + '/SATURN.apk'
  $payload = @{ version=$version; build=$build; apk_url=$url; sha256=$sha; notes='Atualizacao assinada SATURN Android.' }
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress)))
  $metadata = & gh api ("repos/" + $repo + "/contents/update.json") | ConvertFrom-Json
  if ($LASTEXITCODE -ne 0 -or -not $metadata.sha) { throw 'Nao foi possivel atualizar manifesto.' }
  $body = @{message='release: SATURN ' + $version + ' build ' + $build; branch='main'; sha=$metadata.sha; content=$b64} | ConvertTo-Json -Compress
  $bodyPath = Join-Path $temp 'update-payload.json'
  [IO.File]::WriteAllText($bodyPath, $body, (New-Object Text.UTF8Encoding($false)))
  & gh api -X PUT ("repos/" + $repo + "/contents/update.json") --input $bodyPath | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'APK enviado; atualize o manifesto manualmente.' }
  Write-Host ('Publicado: ' + $url) -ForegroundColor Green
  Write-Host 'Agora Atualizar SATURN no Android encontrara o novo build.'
}
finally {
  Remove-Item Env:\SATURN_KEY_ALIAS -ErrorAction SilentlyContinue
  Remove-Item Env:\SATURN_KEY_PASSWORD -ErrorAction SilentlyContinue
  Remove-Item Env:\SATURN_KEYSTORE_PASSWORD -ErrorAction SilentlyContinue
  $pass = $null
  if ($patched -and $null -ne $originalGradle -and (Test-Path $gradle)) {
    [IO.File]::WriteAllText($gradle, $originalGradle,
      (New-Object Text.UTF8Encoding($false)))
  }
  if ($patched -and $null -ne $originalManifest -and (Test-Path $manifest)) {
    [IO.File]::WriteAllText($manifest, $originalManifest,
      (New-Object Text.UTF8Encoding($false)))
  }
  if ($copiedKey -and (Test-Path $localKey)) { Remove-Item $localKey -Force }
  if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
}
