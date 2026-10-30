Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Text;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class BrowserTester {
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

    public static void FocusAndCapture(string pattern, string outPath) {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault != IntPtr.Zero) {
                SetThreadDesktop(hDefault);

                // First minimize other big windows
                EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                    if (IsWindowVisible(hWnd)) {
                        StringBuilder sb = new StringBuilder(256);
                        GetWindowText(hWnd, sb, 256);
                        string txt = sb.ToString();
                        if (txt.IndexOf("Docker and Docker Compose", StringComparison.OrdinalIgnoreCase) >= 0) {
                            ShowWindow(hWnd, 6); // SW_MINIMIZE
                        }
                    }
                    return true;
                }, IntPtr.Zero);

                // Now find and bring target window to top
                IntPtr targetHWnd = IntPtr.Zero;
                EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                    if (IsWindowVisible(hWnd)) {
                        StringBuilder sb = new StringBuilder(256);
                        GetWindowText(hWnd, sb, 256);
                        string txt = sb.ToString();
                        Console.WriteLine("Candidate Window: " + hWnd + " -> " + txt);
                        if (txt.IndexOf(pattern, StringComparison.OrdinalIgnoreCase) >= 0 || txt.IndexOf("Edge", StringComparison.OrdinalIgnoreCase) >= 0 || txt.IndexOf("Chrome", StringComparison.OrdinalIgnoreCase) >= 0) {
                            targetHWnd = hWnd;
                            ShowWindow(hWnd, 3); // SW_MAXIMIZE
                            SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 1280, 800, 0x0040);
                            SetForegroundWindow(hWnd);
                            return false;
                        }
                    }
                    return true;
                }, IntPtr.Zero);

                Thread.Sleep(1500);

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

                CloseDesktop(hDefault);
            }
        });
        t.Start();
        t.Join();
    }
}
"@

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$proc = Start-Process $edgePath -ArgumentList "--new-window", "http://localhost:5173" -PassThru
Start-Sleep -Seconds 4

[BrowserTester]::FocusAndCapture("react-lab", "$env:TEMP\edge_final_test.png")
Write-Host "Captured: $(Test-Path "$env:TEMP\edge_final_test.png")"
