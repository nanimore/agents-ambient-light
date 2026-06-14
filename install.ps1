# Quick Installation Script for Windows
# Run in PowerShell: .\install.ps1

Write-Host "Installing Agents Ambient Light for Claude Code..." -ForegroundColor Cyan

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python not found. Please install Python 3.7+ first." -ForegroundColor Red
    exit 1
}

# Install PyQt5
Write-Host "`nInstalling PyQt5..." -ForegroundColor Cyan
pip install PyQt5

# Copy files
$targetDir = "$env:USERPROFILE\.claude"
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

Write-Host "`nCopying files to $targetDir..." -ForegroundColor Cyan
Copy-Item "ambient-light-qt.py" "$targetDir\"
Copy-Item "ambient-light-config.yaml" "$targetDir\"
Copy-Item "notify.ps1" "$targetDir\"

Write-Host "✓ Files copied successfully" -ForegroundColor Green

# Test
Write-Host "`nTesting ambient light (3 seconds)..." -ForegroundColor Cyan
python "$targetDir\ambient-light-qt.py" --color green --duration 3 --style border --animation breathe

Write-Host "`n✓ Installation complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Edit $env:USERPROFILE\.claude\settings.json to add hooks (see README.md)"
Write-Host "2. Customize colors/settings in $env:USERPROFILE\.claude\ambient-light-config.yaml"
Write-Host "3. Restart Claude Code"
