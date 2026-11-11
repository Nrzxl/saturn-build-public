# SATURN - configurar somente a ASSINATURA ORIGINAL no GitHub publico
# Windows PowerShell 5.1+, Java keytool, Android SDK build-tools, GitHub CLI.
# Nunca gera nova chave e nunca imprime senhas, base64 da chave ou tokens.
param(
    [string]$KeystorePath = "",
    [string]$Repository = "Nrzxl/saturn-build-public"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$originalUrl = "https://github.com/Nrzxl/saturn-downloads/releases/download/v0.6.0-b1008/SATURN.apk"
$originalSha = "cb0a0763036cecb4f8c797d49649c53e908b8851c9b1ef90842d72693218619e"
$alias = "saturn"

function Secret-Read([string]$Prompt) {
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

function Require-Program([string]$Name, [string[]]$Candidates) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }
    throw "Ferramenta ausente: $Name. Instale Java 17/Android SDK/GitHub CLI antes de continuar."
}

function Set-ActionSecret([string]$Name, [string]$Value, [string]$GitHubCli) {
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $GitHubCli
    $info.Arguments = "secret set $Name -R Nrzxl/saturn-build-public --app actions"
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.CreateNoWindow = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $info
    try {
        if (-not $proc.Start()) { throw "GitHub CLI nao iniciou." }
        $proc.StandardInput.Write($Value)
        $proc.StandardInput.Close()
        $err = $proc.StandardError.ReadToEnd()
        $null = $proc.StandardOutput.ReadToEnd()
        $proc.WaitForExit()
        if ($proc.ExitCode -ne 0) { throw "Falha configurando $Name. $err" }
        Write-Host "OK: $Name" -ForegroundColor Green
    } finally { $proc.Dispose() }
}

if ($Repository -ne "Nrzxl/saturn-build-public") {
    throw "Destino nao autorizado. Configure apenas Nrzxl/saturn-build-public."
}

if (-not $KeystorePath) {
    $KeystorePath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "SATURN_SIGNING\saturn-release.keystore"
}
if (-not (Test-Path -LiteralPath $KeystorePath)) {
    throw "ASSINATURA ORIGINAL NAO LOCALIZADA em: $KeystorePath. Localize o arquivo saturn-release.keystore original e execute novamente com -KeystorePath 'CAMINHO'. NUNCA gere uma nova chave para atualizar o SATURN."
}

$gh = Require-Program "gh.exe" @()
$java = Require-Program "keytool.exe" @(
    $(if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\keytool.exe" } else { "" }),
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
)
$roots = @(
    $env:ANDROID_HOME,
    $env:ANDROID_SDK_ROOT,
    (Join-Path $env:LOCALAPPDATA "Android\Sdk")
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
$apksigner = $null
foreach ($root in $roots) {
    $folder = Join-Path $root "build-tools"
    if (-not (Test-Path $folder)) { continue }
    $candidates = @(Get-ChildItem -LiteralPath $folder -Directory |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName "apksigner.bat" } |
        Where-Object { Test-Path $_ })
    if ($candidates.Count -gt 0) { $apksigner = $candidates[0]; break }
}
if (-not $apksigner) {
    throw "Android SDK Build-Tools/apksigner.bat nao encontrado. Instale pelo Android Studio SDK Manager."
}

& $gh auth status -h github.com
if ($LASTEXITCODE -ne 0) { throw "Execute gh auth login antes de continuar." }
$account = [string](& $gh api user --jq .login)
if ($LASTEXITCODE -ne 0 -or $account.Trim() -ne "Nrzxl") {
    throw "Conta GitHub ativa diferente de Nrzxl. Execute gh auth switch -u Nrzxl."
}

Write-Host ""
Write-Host "SATURN: usando apenas a assinatura permanente original" -ForegroundColor Cyan
Write-Host "Arquivo encontrado: $KeystorePath"
Write-Host "Verificando certificado contra APK oficial 0.6.0 antes de qualquer secret..."
Write-Host ""

$storePass = Secret-Read "Senha do keystore ORIGINAL"
$keyPass = Secret-Read "Senha da chave (Enter se for igual a senha do keystore)"
if ([string]::IsNullOrEmpty($keyPass)) { $keyPass = $storePass }
if (-not $storePass) { throw "A senha original e obrigatoria." }

$temp = Join-Path $env:TEMP ("SATURN_cert_check_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $temp | Out-Null
$env:SATURN_TMP_STORE_PASS = $storePass
try {
    $pemOutput = (& $java -exportcert -rfc -alias $alias -keystore $KeystorePath -storepass:env SATURN_TMP_STORE_PASS 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { throw "Senha, alias ou arquivo original invalidos." }
    $match = [regex]::Match($pemOutput, "(?s)-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----")
    if (-not $match.Success) { throw "Nao foi possivel ler o certificado da chave." }
    $der = [Convert]::FromBase64String(($match.Groups[1].Value -replace "\s", ""))
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $keyFingerprint = ([BitConverter]::ToString($sha.ComputeHash($der))).Replace("-", "").ToLowerInvariant()
    } finally { $sha.Dispose() }

    $download = Join-Path $temp "saturn-original.apk"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $originalUrl -OutFile $download -UseBasicParsing
    $downloadSha = (Get-FileHash -Path $download -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($downloadSha -ne $originalSha) {
        throw "APK publico diferente do hash oficial: verificacao bloqueada."
    }
    $signerOutput = (& $apksigner verify --print-certs $download 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { throw "APK publico original nao passou na verificacao." }
    $matchCert = [regex]::Match($signerOutput, "Signer #1 certificate SHA-256 digest:\s*([a-fA-F0-9]+)")
    if (-not $matchCert.Success) { throw "Certificado do APK original indisponivel." }
    $originalFingerprint = $matchCert.Groups[1].Value.ToLowerInvariant()
    if ($keyFingerprint -ne $originalFingerprint) {
        throw "A CHAVE NAO COINCIDE com o SATURN 0.6.0. Nada foi enviado ao GitHub. Localize a chave correta."
    }

    Write-Host "Certificado original validado: compativel com SATURN 0.6.0." -ForegroundColor Green
    Write-Host "Enviando somente para os GitHub Actions Secrets de Nrzxl/saturn-build-public."
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($KeystorePath))
    Set-ActionSecret "SATURN_KEYSTORE_BASE64" $b64 $gh
    Set-ActionSecret "SATURN_KEYSTORE_PASSWORD" $storePass $gh
    Set-ActionSecret "SATURN_KEY_ALIAS" $alias $gh
    Set-ActionSecret "SATURN_KEY_PASSWORD" $keyPass $gh
    $b64 = $null
} finally {
    Remove-Item Env:\SATURN_TMP_STORE_PASS -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    $storePass = $null
    $keyPass = $null
}

Write-Host ""
Write-Host "O ultimo secret permite publicar em Nrzxl/saturn-downloads." -ForegroundColor Yellow
Write-Host "Crie um Fine-grained PAT: acesso SOMENTE ao repo saturn-downloads, Contents Read and write."
Write-Host "Nao cole seu token no chat; o prompt abaixo recebe o token localmente."
$token = Secret-Read "SATURN_RELEASE_TOKEN (Enter para deixar pendente)"
if (-not [string]::IsNullOrWhiteSpace($token)) {
    try {
        Set-ActionSecret "SATURN_RELEASE_TOKEN" $token $gh
    } finally { $token = $null }
} else {
    Write-Host "PENDENTE: SATURN_RELEASE_TOKEN. Sem ele, o release nao sera publicado." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Configuracao concluida sem publicar APK." -ForegroundColor Green
Write-Host "Depois abra:"
Write-Host "https://github.com/Nrzxl/saturn-build-public/actions/workflows/android-public-release.yml"
Write-Host "Clique em Run workflow e selecione main. O GitHub verificara novamente a assinatura antes de publicar."
