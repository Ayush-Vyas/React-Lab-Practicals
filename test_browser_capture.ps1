param([string]$OutFile)

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$profileDir = "$env:TEMP\EdgeDockerDemo"
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$proc = Start-Process -FilePath $edgePath -ArgumentList "--user-data-dir=$profileDir", "--no-first-run", "--no-default-browser-check", "--start-maximized", "http://localhost:5173" -PassThru
Start-Sleep -Seconds 4

[WinDesktop]::FocusWindowByTitle("Edge")
Start-Sleep -Milliseconds 800

[WinDesktop]::Capture($OutFile)
Write-Host "Captured browser: $OutFile ($( (Get-Item $OutFile).Length ) bytes)"

Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
