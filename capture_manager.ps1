param(
    [string]$Action,
    [string]$Title,
    [string]$OutputPath,
    [string]$Command
)

$code = @"
using System;
using System.Text;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class DesktopManager {
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

    public static void ShowWindowByTitle(string titlePattern, bool topMost) {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault != IntPtr.Zero) {
                SetThreadDesktop(hDefault);
                EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                    if (IsWindowVisible(hWnd)) {
                        StringBuilder sb = new StringBuilder(256);
                        GetWindowText(hWnd, sb, 256);
                        string text = sb.ToString();
                        if (text.IndexOf(titlePattern, StringComparison.OrdinalIgnoreCase) >= 0) {
                            ShowWindow(hWnd, 3); // SW_MAXIMIZE
                            if (topMost) {
                                SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 1280, 800, 0x0040); // HWND_TOPMOST | SWP_SHOWWINDOW
                            }
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
                        string text = sb.ToString();
                        if (text.IndexOf(titlePattern, StringComparison.OrdinalIgnoreCase) >= 0) {
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

    public static bool CaptureScreen(string filePath) {
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

if (-not ([System.Management.Automation.PSTypeName]'DesktopManager').Type) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition $code
}

switch ($Action) {
    "Capture" {
        $dir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [DesktopManager]::CaptureScreen($OutputPath)
        Write-Host "Captured to $($OutputPath) - exists: $(Test-Path $OutputPath)"
    }
    "Focus" {
        [DesktopManager]::ShowWindowByTitle($Title, $true)
    }
    "Minimize" {
        [DesktopManager]::MinimizeWindowByTitle($Title)
    }
}
