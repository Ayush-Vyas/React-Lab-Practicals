Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Text;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class WinDesktop {
    public delegate bool EnumDesktopWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr OpenDesktop(string lpszDesktop, uint dwFlags, bool fInherit, uint dwDesiredAccess);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetThreadDesktop(IntPtr hDesktop);

    [DllImport("user32.dll")]
    public static extern bool EnumDesktopWindows(IntPtr hDesktop, EnumDesktopWindowsProc lpfn, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool CloseDesktop(IntPtr hDesktop);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetDC(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr CreateCompatibleDC(IntPtr hDC);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC, int nWidth, int nHeight);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool BitBlt(IntPtr hObject, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hObjectSource, int nXSrc, int nYSrc, int dwRop);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool DeleteDC(IntPtr hDC);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern bool DeleteObject(IntPtr hObject);

    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);

    public static void FocusWindowByTitle(string titlePattern) {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault != IntPtr.Zero) {
                SetThreadDesktop(hDefault);
                EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                    if (IsWindowVisible(hWnd)) {
                        StringBuilder sb = new StringBuilder(256);
                        GetWindowText(hWnd, sb, 256);
                        string winText = sb.ToString();
                        if (winText.IndexOf(titlePattern, StringComparison.OrdinalIgnoreCase) >= 0) {
                            ShowWindow(hWnd, 3); // SW_MAXIMIZE
                            SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 1280, 800, 0x0040);
                            SetForegroundWindow(hWnd);
                            return false;
                        }
                    }
                    return true;
                }, IntPtr.Zero);
                CloseDesktop(hDefault);
            }
        });
        t.Start();
        t.Join();
    }

    public static void MinimizeWindowByTitle(string titlePattern) {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault != IntPtr.Zero) {
                SetThreadDesktop(hDefault);
                EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                    if (IsWindowVisible(hWnd)) {
                        StringBuilder sb = new StringBuilder(256);
                        GetWindowText(hWnd, sb, 256);
                        string winText = sb.ToString();
                        if (winText.IndexOf(titlePattern, StringComparison.OrdinalIgnoreCase) >= 0) {
                            ShowWindow(hWnd, 6); // SW_MINIMIZE
                        }
                    }
                    return true;
                }, IntPtr.Zero);
                CloseDesktop(hDefault);
            }
        });
        t.Start();
        t.Join();
    }

    public static bool Capture(string filePath) {
        bool result = false;
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault == IntPtr.Zero) return;
            if (SetThreadDesktop(hDefault)) {
                int w = GetSystemMetrics(0);
                int h = GetSystemMetrics(1);
                IntPtr hDC = GetDC(IntPtr.Zero);
                IntPtr memDC = CreateCompatibleDC(hDC);
                IntPtr hBmp = CreateCompatibleBitmap(hDC, w, h);
                IntPtr hOld = SelectObject(memDC, hBmp);
                bool blt = BitBlt(memDC, 0, 0, w, h, hDC, 0, 0, 0x00CC0020);
                if (blt) {
                    using (Bitmap bmp = Bitmap.FromHbitmap(hBmp)) {
                        bmp.Save(filePath, ImageFormat.Png);
                        result = true;
                    }
                }
                SelectObject(memDC, hOld);
                DeleteDC(memDC);
                ReleaseDC(IntPtr.Zero, hDC);
                DeleteObject(hBmp);
            }
            CloseDesktop(hDefault);
        });
        t.Start();
        t.Join();
        return result;
    }
}
"@

$targetDir = "C:\Users\Ayush\Downloads\Practical11_Screenshots"
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

function Capture-TerminalStep {
    param(
        [string]$StepTitle,
        [string]$ScriptContent,
        [string]$OutputFile
    )

    Write-Host ">>> Running: $StepTitle"
    $runnerPath = "$env:TEMP\step_runner.ps1"
    Set-Content -Path $runnerPath -Value $ScriptContent

    $proc = Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $runnerPath -PassThru
    Start-Sleep -Seconds 3

    [WinDesktop]::FocusWindowByTitle($StepTitle)
    Start-Sleep -Milliseconds 800

    [WinDesktop]::Capture($OutputFile)
    Write-Host "[OK] Saved: $OutputFile ($( (Get-Item $OutputFile).Length ) bytes)"

    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

Write-Host "Starting Practical 11 Evidence Generation..."

# 01 Docker Version
$s1 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - Docker & Docker Compose Version Check"
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: DOCKER & DOCKER COMPOSE CONTAINERIZATION" -ForegroundColor Green
Write-Host " Environment Verification: Docker Engine & CLI Versions" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker --version" -ForegroundColor White
docker --version
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose version" -ForegroundColor White
docker compose version
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker version" -ForegroundColor White
docker version
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Start-Sleep 30
'@
Capture-TerminalStep -StepTitle "Practical 11 - Docker & Docker Compose Version Check" -ScriptContent $s1 -OutputFile "$targetDir\01_Docker_Version.png"

# 02 Backend Dockerfile
$s2 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - Backend Dockerfile & Configuration"
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: BACKEND DOCKERFILE & .DOCKERIGNORE" -ForegroundColor Green
Write-Host " Service: Node.js 20 Express REST API" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> Get-Content .\backend\Dockerfile" -ForegroundColor White
Get-Content .\backend\Dockerfile
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> Get-Content .\backend\.dockerignore" -ForegroundColor White
Get-Content .\backend\.dockerignore
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Start-Sleep 30
'@
Capture-TerminalStep -StepTitle "Practical 11 - Backend Dockerfile & Configuration" -ScriptContent $s2 -OutputFile "$targetDir\02_Backend_Dockerfile.png"

# 03 Frontend Dockerfile
$s3 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - Frontend Multi-Stage Dockerfile & Nginx Config"
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: FRONTEND DOCKERFILE (VITE BUILD -> NGINX)" -ForegroundColor Green
Write-Host " Service: React 19 + Vite SPA with Nginx Reverse Proxy" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> Get-Content .\Dockerfile" -ForegroundColor White
Get-Content .\Dockerfile
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> Get-Content .\nginx.conf" -ForegroundColor White
Get-Content .\nginx.conf
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> Get-Content .\.dockerignore" -ForegroundColor White
Get-Content .\.dockerignore
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Start-Sleep 30
'@
Capture-TerminalStep -StepTitle "Practical 11 - Frontend Multi-Stage Dockerfile & Nginx Config" -ScriptContent $s3 -OutputFile "$targetDir\03_Frontend_Dockerfile.png"

# 04 Docker Compose
$s4 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - Multi-Container docker-compose.yml"
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: ROOT DOCKER-COMPOSE.YML SPECIFICATION" -ForegroundColor Green
Write-Host " Multi-Container Setup: Frontend + Backend + MongoDB + Bridge Network + Named Volume" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> Get-Content .\docker-compose.yml" -ForegroundColor White
Get-Content .\docker-compose.yml
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Start-Sleep 30
'@
Capture-TerminalStep -StepTitle "Practical 11 - Multi-Container docker-compose.yml" -ScriptContent $s4 -OutputFile "$targetDir\04_Docker_Compose.png"

# 05 Image Builds
$s5 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - Docker Compose Build Execution"
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: DOCKER COMPOSE IMAGE BUILDS" -ForegroundColor Green
Write-Host " Executing: docker compose build" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose build" -ForegroundColor White
docker compose build
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker images | Select-String 'react-lab|mongo'" -ForegroundColor White
docker images | Select-String "react-lab|mongo"
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Start-Sleep 30
'@
Capture-TerminalStep -StepTitle "Practical 11 - Docker Compose Build Execution" -ScriptContent $s5 -OutputFile "$targetDir\05_Image_Builds.png"

# 06 Container Startup & Logs
$s6 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - Container Startup & Service Telemetry"
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: CONTAINER STARTUP & HEALTH VERIFICATION" -ForegroundColor Green
Write-Host " Executing: docker compose up -d & docker compose logs" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose up -d" -ForegroundColor White
docker compose up -d
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose logs --tail=15 backend" -ForegroundColor White
docker compose logs --tail=15 backend
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Start-Sleep 30
'@
Capture-TerminalStep -StepTitle "Practical 11 - Container Startup & Service Telemetry" -ScriptContent $s6 -OutputFile "$targetDir\06_Container_Startup.png"

# 07 Docker PS Status
$s7 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - Docker PS & Container Port Mappings"
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: RUNNING CONTAINERS AND PORT INSPECTION" -ForegroundColor Green
Write-Host " Verifying Services: task-frontend, task-backend, task-mongodb" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose ps" -ForegroundColor White
docker compose ps
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker network inspect react-lab-practicals_app-network | Select-String 'Name|IPv4Address'" -ForegroundColor White
docker network inspect react-lab-practicals_app-network | Select-String "Name|IPv4Address"
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker volume ls | Select-String 'mongo-data'" -ForegroundColor White
docker volume ls | Select-String "mongo-data"
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Start-Sleep 30
'@
Capture-TerminalStep -StepTitle "Practical 11 - Docker PS & Container Port Mappings" -ScriptContent $s7 -OutputFile "$targetDir\07_Docker_PS.png"

# 10 Data Persistence Verification
$s10 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - MongoDB Persistence Across Container Restarts"
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: NAMED VOLUME DATA PERSISTENCE VERIFICATION" -ForegroundColor Green
Write-Host " Testing Container Teardown, Recreation, and MongoDB Record Integrity" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Testing Container Teardown:" -ForegroundColor White
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose down" -ForegroundColor White
docker compose down
Write-Host ""
Write-Host "2. Relaunching Multi-Container Application:" -ForegroundColor White
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose up -d" -ForegroundColor White
docker compose up -d
Start-Sleep 3
Write-Host ""
Write-Host "3. Verifying Container Status:" -ForegroundColor White
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose ps" -ForegroundColor White
docker compose ps
Write-Host ""
Write-Host "4. Querying Tasks via API from Persisted MongoDB Volume:" -ForegroundColor White
$loginBody = @{ email = "docker_test@example.com"; password = "password123" } | ConvertTo-Json
$loginRes = Invoke-RestMethod -Uri "http://localhost:5000/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.token
$persistedTasks = Invoke-RestMethod -Uri "http://localhost:5000/tasks" -Method Get -Headers @{ Authorization = "Bearer $token" }
Write-Host "[OK] Verified $($persistedTasks.Count) Persisted Document(s) Loaded from mongo-data Volume:" -ForegroundColor Green
$persistedTasks | ForEach-Object { Write-Host " - [$($_.priority.ToUpper())] $($_.title) (ID: $($_._id))" -ForegroundColor Cyan }
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Start-Sleep 30
'@
Capture-TerminalStep -StepTitle "Practical 11 - MongoDB Persistence Across Container Restarts" -ScriptContent $s10 -OutputFile "$targetDir\10_Data_Persistence_Verification.png"

Write-Host "Terminal Screenshots (1-7, 10) Generated Successfully!"
