$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "Backend"
if (-not (Test-Path (Join-Path $backend "package.json"))) {
  $backend = Join-Path $root "backend"
}
$frontend = Join-Path $root "Frontend"
if (-not (Test-Path (Join-Path $frontend "pubspec.yaml"))) {
  $frontend = Join-Path $root "frontend"
}

function Test-Backend {
  try {
    $res = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 2 -UseBasicParsing
    return $res.StatusCode -eq 200
  } catch {
    return $false
  }
}

if (-not (Test-Backend)) {
  Write-Host "Starting Backend..."
  Start-Process -FilePath "npm" -ArgumentList "run","dev" -WorkingDirectory $backend -WindowStyle Minimized
  $ready = $false
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-Backend) {
      Write-Host "Backend is ready."
      $ready = $true
      break
    }
  }
  if (-not $ready) {
    Write-Host "Backend did not become ready on http://localhost:3000"
  }
} else {
  Write-Host "Backend already running."
}

Set-Location $frontend
$device = $args[0]
if ([string]::IsNullOrWhiteSpace($device)) {
  flutter run
} else {
  flutter run -d $device
}
