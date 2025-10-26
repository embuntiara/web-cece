<#
  Helper PowerShell script to:
  - build docker images (docker compose build)
  - run containers (docker compose up -d)
  - wait for MySQL to be ready
  - run Laravel migrations inside the `app` service
  - optionally commit & push repo changes to the current branch

  Usage (PowerShell):
    .\scripts\docker-build-run-migrate.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Move to script folder (assumes script lives in repo/scripts)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir\..  

Write-Host "[docker] Building images..."
docker compose build

Write-Host "[docker] Starting containers..."
docker compose up -d

Write-Host "[docker] Waiting for MySQL to be ready (this may take a few seconds)..."
$maxSeconds = 60
$ready = $false
for ($i = 0; $i -lt $maxSeconds; $i++) {
    try {
        docker compose exec -T mysql mysql -uroot -proot -e "SELECT 1;" > $null 2>&1
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    } catch {
        # ignore and retry
    }
    Start-Sleep -Seconds 1
}

if (-not $ready) {
    Write-Host "[docker] Warning: MySQL did not become ready within $maxSeconds seconds. You can try running migrations later." -ForegroundColor Yellow
} else {
    Write-Host "[docker] MySQL is ready. Running migrations..."
    docker compose exec -T app php artisan migrate --force
}

Write-Host "[git] Staging changes (if any)..."
git add -A

$status = git status --porcelain
if ($status) {
    $branch = git rev-parse --abbrev-ref HEAD
    $msg = "chore(docker): build/run and run migrations"
    git commit -m $msg
    Write-Host "[git] Pushing commit to origin/$branch..."
    git push origin $branch
} else {
    Write-Host "[git] No changes to commit. Nothing to push."
}

Write-Host "Done."
