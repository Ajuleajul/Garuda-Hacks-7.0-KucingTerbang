$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Test-Path .env)) {
  Write-Error "Missing Backend/.env — copy from .env.example and fill DATABASE_URL + DATA_ENCRYPTION_KEY"
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Starting Docker Desktop..."
  Start-Process "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
  $deadline = (Get-Date).AddMinutes(2)
  do {
    Start-Sleep -Seconds 3
    docker info *> $null
    if ($LASTEXITCODE -eq 0) { break }
  } while ((Get-Date) -lt $deadline)
  if ($LASTEXITCODE -ne 0) { throw "Docker Desktop not ready. Open it manually, wait until green, rerun." }
}

docker compose up -d --build
Start-Sleep -Seconds 3
Invoke-RestMethod "http://localhost:3000/health" | ConvertTo-Json
Write-Host "`nAPI: http://localhost:3000"
Write-Host "Logs: docker compose logs -f api"
