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
  if ($version -eq '0.1.3') {
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
Instalar 'https://d607e34b.escriba-72v.pages.dev/descargas/Escriba-Windows-x64.exe' '559f17e50c7e6594170416d01b5f48faef03a8841eef98bbf7ae53c82ff796c1' '0.1.2'
Instalar 'https://bae03e44.escriba-72v.pages.dev/descargas/Escriba-Windows-x64.exe' 'c42515009a8478aefe4c8357fc13a6ab2ad8244d5de0420ae17f323391ee41e5' '0.1.3'
