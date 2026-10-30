Add-Type -ReferencedAssemblies System.Drawing, System.Windows.Forms -TypeDefinition @"
using System;
using System.Text;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class BrowserProjectLogin {
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
    public const byte VK_SHIFT   = 0x10;
    public const byte VK_J       = 0x4A;
    public const byte VK_V       = 0x56;
    public const byte VK_RETURN  = 0x0D;
    public const byte VK_F12     = 0x7B;
    public const uint KEYEVENTF_KEYUP = 0x0002;

    public static void PressKey(byte vk) {
        keybd_event(vk, 0, 0, 0);
        Thread.Sleep(50);
        keybd_event(vk, 0, KEYEVENTF_KEYUP, 0);
        Thread.Sleep(50);
    }

    public static void PressCtrlV() {
        keybd_event(VK_CONTROL, 0, 0, 0);
        Thread.Sleep(50);
        keybd_event(VK_V, 0, 0, 0);
        Thread.Sleep(50);
        keybd_event(VK_V, 0, KEYEVENTF_KEYUP, 0);
        Thread.Sleep(50);
        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
        Thread.Sleep(50);
    }

    public static void PressCtrlShiftJ() {
        keybd_event(VK_CONTROL, 0, 0, 0);
        keybd_event(VK_SHIFT, 0, 0, 0);
        Thread.Sleep(50);
        keybd_event(VK_J, 0, 0, 0);
        Thread.Sleep(50);
        keybd_event(VK_J, 0, KEYEVENTF_KEYUP, 0);
        Thread.Sleep(50);
        keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);
        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
        Thread.Sleep(50);
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

    public static void LoginAndNavigate(string outPath) {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault == IntPtr.Zero) return;
            SetThreadDesktop(hDefault);

            // Minimize Antigravity
            EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                if (IsWindowVisible(hWnd)) {
                    StringBuilder sb = new StringBuilder(256);
                    GetWindowText(hWnd, sb, 256);
                    string txt = sb.ToString();
                    if (txt.IndexOf("Docker and Docker Compose", StringComparison.OrdinalIgnoreCase) >= 0) {
                        ShowWindow(hWnd, 6);
                    }
                }
                return true;
            }, IntPtr.Zero);

            Thread.Sleep(500);

            // Find and bring react-lab-practicals to foreground
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

            if (reactWin == IntPtr.Zero) {
                CloseDesktop(hDefault);
                return;
            }

            Thread.Sleep(800);

            // Open DevTools console
            PressCtrlShiftJ();
            Thread.Sleep(2000);

            // Set clipboard and paste
            string code = "fetch('http://localhost:5000/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'docker_test@example.com',password:'password123'})}).then(r=>r.json()).then(d=>{localStorage.setItem('token',d.token);localStorage.setItem('user',JSON.stringify(d.user));location.href='/projects';});";
            Clipboard.SetText(code);
            PressCtrlV();
            Thread.Sleep(200);
            PressKey(VK_RETURN);

            // Wait 3 seconds for login response and redirect to /projects
            Thread.Sleep(3000);

            // Close DevTools so the full UI is visible
            PressKey(VK_F12);
            Thread.Sleep(1500);

            // Capture 09_Browser_Task_CRUD.png
            CaptureScreen(outPath);

            CloseDesktop(hDefault);
        });
        t.SetApartmentState(ApartmentState.STA); // STA required for Clipboard
        t.Start();
        t.Join();
    }
}
"@

$outFile = "C:\Users\Ayush\Downloads\Practical11_Screenshots\09_Browser_Task_CRUD.png"
[BrowserProjectLogin]::LoginAndNavigate($outFile)
Write-Host "Saved 09: $(Test-Path $outFile) ($( (Get-Item $outFile).Length ) bytes)"
