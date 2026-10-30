Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Text;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class Zoomer {
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
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool CloseDesktop(IntPtr hDesktop);

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

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

    public const byte VK_CONTROL = 0x11;
    public const byte VK_OEM_MINUS = 0xBD;
    public const byte VK_HOME = 0x24;
    public const uint KEYEVENTF_KEYUP = 0x0002;

    public static void ZoomOutAndSnap(string outPath) {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault == IntPtr.Zero) return;
            SetThreadDesktop(hDefault);

            IntPtr reactWin = IntPtr.Zero;
            EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                if (IsWindowVisible(hWnd)) {
                    StringBuilder sb = new StringBuilder(256);
                    GetWindowText(hWnd, sb, 256);
                    string txt = sb.ToString();
                    if (txt.IndexOf("react-lab-practicals", StringComparison.OrdinalIgnoreCase) >= 0) {
                        reactWin = hWnd;
                        ShowWindow(hWnd, 3);
                        SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 1280, 800, 0x0040);
                        SetForegroundWindow(hWnd);
                        return false;
                    }
                }
                return true;
            }, IntPtr.Zero);

            if (reactWin != IntPtr.Zero) {
                Thread.Sleep(500);

                // Scroll to top first
                keybd_event(VK_HOME, 0, 0, 0);
                Thread.Sleep(50);
                keybd_event(VK_HOME, 0, KEYEVENTF_KEYUP, 0);
                Thread.Sleep(300);

                // Ctrl+- three times
                for (int i = 0; i < 3; i++) {
                    keybd_event(VK_CONTROL, 0, 0, 0);
                    Thread.Sleep(50);
                    keybd_event(VK_OEM_MINUS, 0, 0, 0);
                    Thread.Sleep(50);
                    keybd_event(VK_OEM_MINUS, 0, KEYEVENTF_KEYUP, 0);
                    Thread.Sleep(50);
                    keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
                    Thread.Sleep(200);
                }

                Thread.Sleep(1000);

                int w = GetSystemMetrics(0);
                int h = GetSystemMetrics(1);
                IntPtr hDC = GetDC(IntPtr.Zero);
                IntPtr memDC = CreateCompatibleDC(hDC);
                IntPtr hBmp = CreateCompatibleBitmap(hDC, w, h);
                IntPtr hOld = SelectObject(memDC, hBmp);
                bool blt = BitBlt(memDC, 0, 0, w, h, hDC, 0, 0, 0x00CC0020);
                if (blt) {
                    using (Bitmap bmp = Bitmap.FromHbitmap(hBmp)) {
                        bmp.Save(outPath, ImageFormat.Png);
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
    }
}
"@

$testOut = "$env:TEMP\test_zoomed_login.png"
[Zoomer]::ZoomOutAndSnap($testOut)
Write-Host "Zoomed capture: $(Test-Path $testOut)"
