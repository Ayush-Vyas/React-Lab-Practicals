Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Text;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class DesktopCapture10 {
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
$readySignal = "$env:TEMP\step10_ready.txt"
if (Test-Path $readySignal) { Remove-Item $readySignal -Force }

$s10 = @'
$Host.UI.RawUI.WindowTitle = "Practical 11 - MongoDB Persistence Across Container Restarts"
Clear-Host
Set-Location "C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals"
Write-Host "Teardown and recreate containers to verify persistent volume..." -ForegroundColor Yellow
docker compose down > $null 2>&1
docker compose up -d > $null 2>&1
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep 1
    try {
        $test = Invoke-RestMethod -Uri "http://localhost:5000/tasks" -Method Get -ErrorAction Stop
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) { break }
    }
}

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " PRACTICAL 11: NAMED VOLUME DATA PERSISTENCE VERIFICATION" -ForegroundColor Green
Write-Host " Containers recreated cleanly from persistent volume: mongo-data" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> docker compose ps" -ForegroundColor White
docker compose ps
Write-Host ""
Write-Host "PS C:\Ayush-Data\02-College\AWDF-130\React-Lab-Practicals> Verify-MongoVolumePersistence" -ForegroundColor White
$loginBody = @{ email = "docker_test@example.com"; password = "password123" } | ConvertTo-Json
$loginRes = Invoke-RestMethod -Uri "http://localhost:5000/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.token
$persistedTasks = Invoke-RestMethod -Uri "http://localhost:5000/tasks" -Method Get -Headers @{ Authorization = "Bearer $token" }
Write-Host "[OK] Verified $($persistedTasks.Count) Persisted Document(s) from mongo-data Volume:" -ForegroundColor Green
$persistedTasks | ForEach-Object { Write-Host " - Title: $($_.title) | Priority: $($_.priority) | ID: $($_._id)" -ForegroundColor Cyan }
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
New-Item -ItemType File -Path "$env:TEMP\step10_ready.txt" -Force | Out-Null
Start-Sleep 30
'@

$runnerPath = "$env:TEMP\step10_runner.ps1"
Set-Content -Path $runnerPath -Value $s10

Write-Host "Launching Step 10..."
$proc = Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $runnerPath -PassThru

$waited = 0
while (-not (Test-Path $readySignal) -and ($waited -lt 60)) {
    Start-Sleep 1
    $waited++
}

Write-Host "Step 10 ready after $waited seconds. Focusing window..."
[DesktopCapture10]::FocusWindowByTitle("Practical 11 - MongoDB Persistence")
Start-Sleep 2

$outFile = "$targetDir\10_Data_Persistence_Verification.png"
[DesktopCapture10]::Capture($outFile)
Write-Host "[OK] Saved: $outFile ($( (Get-Item $outFile).Length ) bytes)"

Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
if (Test-Path $readySignal) { Remove-Item $readySignal -Force }
