Add-Type -ReferencedAssemblies System.Drawing, System.Windows.Forms -TypeDefinition @"
using System;
using System.Text;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class BrowserFlow {
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
    public const byte VK_N = 0x4E;
    public const byte VK_OEM_MINUS = 0xBD;
    public const byte VK_TAB = 0x09;
    public const byte VK_RETURN = 0x0D;
    public const uint KEYEVENTF_KEYUP = 0x0002;

    public static void KeyCombo(byte modifier, byte vk) {
        keybd_event(modifier, 0, 0, 0);
        Thread.Sleep(60);
        keybd_event(vk, 0, 0, 0);
        Thread.Sleep(60);
        keybd_event(vk, 0, KEYEVENTF_KEYUP, 0);
        Thread.Sleep(60);
        keybd_event(modifier, 0, KEYEVENTF_KEYUP, 0);
        Thread.Sleep(60);
    }

    public static void KeyPress(byte vk) {
        keybd_event(vk, 0, 0, 0);
        Thread.Sleep(60);
        keybd_event(vk, 0, KEYEVENTF_KEYUP, 0);
        Thread.Sleep(60);
    }

    public static void CaptureScreen(string outPath) {
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

    public static void ExecuteFlow(string img08, string img09) {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault == IntPtr.Zero) return;
            SetThreadDesktop(hDefault);

            // Step A: Find any existing Chrome window and bring to top
            IntPtr existingChrome = IntPtr.Zero;
            EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                if (IsWindowVisible(hWnd)) {
                    StringBuilder sb = new StringBuilder(256);
                    GetWindowText(hWnd, sb, 256);
                    string title = sb.ToString();
                    if (title.IndexOf("Google Chrome", StringComparison.OrdinalIgnoreCase) >= 0) {
                        existingChrome = hWnd;
                        ShowWindow(hWnd, 3);
                        SetForegroundWindow(hWnd);
                        return false;
                    }
                }
                return true;
            }, IntPtr.Zero);

            if (existingChrome == IntPtr.Zero) {
                CloseDesktop(hDefault);
                return;
            }

            Thread.Sleep(500);

            // Step B: Open new Chrome window with Ctrl+N
            KeyCombo(VK_CONTROL, VK_N);
            Thread.Sleep(1200);

            // Navigate to http://localhost:5173/login
            SendKeys.SendWait("http://localhost:5173/login");
            Thread.Sleep(200);
            KeyPress(VK_RETURN);
            Thread.Sleep(2500);

            // Step C: Minimize Antigravity
            EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                if (IsWindowVisible(hWnd)) {
                    StringBuilder sb = new StringBuilder(256);
                    GetWindowText(hWnd, sb, 256);
                    string title = sb.ToString();
                    if (title.IndexOf("Docker and Docker Compose", StringComparison.OrdinalIgnoreCase) >= 0) {
                        ShowWindow(hWnd, 6); // Minimize
                    }
                }
                return true;
            }, IntPtr.Zero);

            Thread.Sleep(500);

            // Step D: Find the react-lab window, maximize, zoom out twice
            IntPtr reactWin = IntPtr.Zero;
            EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                if (IsWindowVisible(hWnd)) {
                    StringBuilder sb = new StringBuilder(256);
                    GetWindowText(hWnd, sb, 256);
                    string title = sb.ToString();
                    if (title.IndexOf("react-lab-practicals", StringComparison.OrdinalIgnoreCase) >= 0) {
                        reactWin = hWnd;
                        ShowWindow(hWnd, 3);
                        SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 1280, 800, 0x0040);
                        SetForegroundWindow(hWnd);
                        return false;
                    }
                }
                return true;
            }, IntPtr.Zero);

            Thread.Sleep(800);
            KeyCombo(VK_CONTROL, VK_OEM_MINUS);
            Thread.Sleep(400);
            KeyCombo(VK_CONTROL, VK_OEM_MINUS);
            Thread.Sleep(1000);

            // Capture 08_Browser_Frontend.png
            CaptureScreen(img08);

            // Step E: Perform Login
            // Tab 3 times to get to Email field:
            KeyPress(VK_TAB);
            Thread.Sleep(200);
            KeyPress(VK_TAB);
            Thread.Sleep(200);
            KeyPress(VK_TAB);
            Thread.Sleep(400);

            // Type email
            SendKeys.SendWait("docker_test@example.com");
            Thread.Sleep(300);
            KeyPress(VK_TAB);
            Thread.Sleep(300);
            // Type password
            SendKeys.SendWait("password123");
            Thread.Sleep(300);
            KeyPress(VK_RETURN);

            // Wait 3 seconds for login and redirection to /projects + fetching tasks
            Thread.Sleep(3000);

            // Capture 09_Browser_Task_CRUD.png
            CaptureScreen(img09);

            CloseDesktop(hDefault);
        });
        t.Start();
        t.Join();
    }
}
"@

$targetDir = "C:\Users\Ayush\Downloads\Practical11_Screenshots"
$p8 = "$targetDir\08_Browser_Frontend.png"
$p9 = "$targetDir\09_Browser_Task_CRUD.png"

Write-Host "Executing Browser Flow for Screenshots 08 and 09..."
[BrowserFlow]::ExecuteFlow($p8, $p9)
Write-Host "08 Exists: $(Test-Path $p8) ($( (Get-Item $p8).Length ) bytes)"
Write-Host "09 Exists: $(Test-Path $p9) ($( (Get-Item $p9).Length ) bytes)"
