$ErrorActionPreference = 'Stop'
$version = '0.1.10'
$url = 'https://github.com/FischMati/escriba-descargas/releases/download/v0.1.10/Escriba_0.1.10_x64-setup.exe'
$hash = '61c26a0212a800ca7a66a7593752a961711fe5c06ebfe6442c200bc07d6f648f'
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
  
  Get-Process escriba-app -ErrorAction SilentlyContinue | Stop-Process -Force
  $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = '--remote-debugging-port=9222'
  $env:WEBVIEW2_USER_DATA_FOLDER = Join-Path $env:RUNNER_TEMP "vista-$version"
  $pol = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2'
  foreach ($item in @('AdditionalBrowserArguments', 'UserDataFolder')) {
    New-Item "$pol\$item" -Force | Out-Null
    $value = if ($item -eq 'UserDataFolder') { $env:WEBVIEW2_USER_DATA_FOLDER } else { $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS }
    New-ItemProperty "$pol\$item" -Name 'escriba-app.exe' -Value $value -PropertyType String -Force | Out-Null
  }

  Start-Process $exe -WorkingDirectory $dir
  node comprobar.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Falló la actualización o no se conservó la sesión' }
  if ((Get-Item $exe).VersionInfo.ProductVersion -notlike '0.1.11*') { throw 'No se instaló la versión publicada' }
