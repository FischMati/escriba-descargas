$ErrorActionPreference = 'Stop'
function Instalar($url, $hash, $version) {
  $setup = Join-Path $env:RUNNER_TEMP "Escriba-$version.exe"
  Invoke-WebRequest $url -OutFile $setup
  if ((Get-FileHash $setup -Algorithm SHA256).Hash -ne $hash) { throw 'Cambió el instalador' }
  $p = Start-Process $setup -ArgumentList '/S' -PassThru -Wait
  if ($p.ExitCode -ne 0) { throw "Instalador: $($p.ExitCode)" }
  $dir = Join-Path $env:LOCALAPPDATA 'Escriba'
  foreach ($f in 'escriba-app.exe','escriba-asr-worker.exe','escriba-llm-worker.exe','vulkan-1.dll') {
    if (-not (Test-Path (Join-Path $dir $f))) { throw "Falta $f" }
  }
  $exe = Join-Path $dir 'escriba-app.exe'
  if ((Get-Item $exe).VersionInfo.ProductVersion -notlike "$version*") { throw 'Versión incorrecta' }
  Get-Process escriba-app -ErrorAction SilentlyContinue | Stop-Process -Force
  $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = '--remote-debugging-port=9222'
  $env:WEBVIEW2_USER_DATA_FOLDER = Join-Path $env:RUNNER_TEMP "vista-$version"
  $pol = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2'
  foreach ($item in @('AdditionalBrowserArguments', 'UserDataFolder')) {
    New-Item "$pol\$item" -Force | Out-Null
    $value = if ($item -eq 'UserDataFolder') { $env:WEBVIEW2_USER_DATA_FOLDER } else { $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS }
    New-ItemProperty "$pol\$item" -Name 'escriba-app.exe' -Value $value -PropertyType String -Force | Out-Null
  }
  if ($version -eq '0.1.7') {
    python voz.py --preparar
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo verificar el modelo de prueba' }
    $env:ESCRIBA_MODELS_DIR = Join-Path $env:RUNNER_TEMP 'modelos-escriba'
    New-Item $env:ESCRIBA_MODELS_DIR -ItemType Directory -Force | Out-Null
    Copy-Item (Join-Path $env:RUNNER_TEMP 'ggml-tiny.bin') $env:ESCRIBA_MODELS_DIR
    Start-Service Audiosrv
  }
  $p = Start-Process $exe -WorkingDirectory $dir -PassThru
  try {
    node comprobar.mjs $version
    if ($LASTEXITCODE -ne 0) { throw 'Falló el recorrido en WebView2' }
  } catch {
    $p.Refresh()
    Write-Host "Activo: $(-not $p.HasExited) Código de salida: $($p.ExitCode) Título: $($p.MainWindowTitle)"
    Get-CimInstance Win32_Process -Filter "Name = 'msedgewebview2.exe'" | Select-Object Name,ProcessId,CommandLine | Format-List
    Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddMinutes(-3);Level=1,2,3} -ErrorAction SilentlyContinue | Select-Object -First 6 ProviderName,Message | Format-List
    throw
  } finally {
    if (-not $p.HasExited) { taskkill /PID $p.Id /T /F | Out-Null }
  }
}
Instalar 'https://github.com/FischMati/escriba-descargas/releases/download/v0.1.6/Escriba_0.1.6_x64-setup.exe' '15efb3b3d70c41ae205ede5e573a3c5c997daa9f2b8f7b198371bdbdd8a53c3f' '0.1.6'
Instalar 'https://16a8792e.escriba-72v.pages.dev/descargas/Escriba-Windows-x64.exe' '3233726c81bb96674faed2ebf3d3475a085c5c9076c100a4724438ef1bdf7a1c' '0.1.7'
