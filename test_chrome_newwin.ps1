Add-Type -ReferencedAssemblies System.Drawing, System.Windows.Forms -TypeDefinition @"
using System;
using System.Text;
using System.Threading;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class ChromeWinController {
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

    public const byte VK_CONTROL = 0x11;
    public const byte VK_N = 0x4E;
    public const uint KEYEVENTF_KEYUP = 0x0002;

    public static void OpenNewWindow(string url) {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault != IntPtr.Zero) {
                SetThreadDesktop(hDefault);

                IntPtr chromeHwnd = IntPtr.Zero;
                EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                    if (IsWindowVisible(hWnd)) {
                        StringBuilder sb = new StringBuilder(256);
                        GetWindowText(hWnd, sb, 256);
                        string title = sb.ToString();
                        if (title.IndexOf("Google Chrome", StringComparison.OrdinalIgnoreCase) >= 0) {
                            chromeHwnd = hWnd;
                            ShowWindow(hWnd, 3); // Maximize
                            SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 1280, 800, 0x0040);
                            SetForegroundWindow(hWnd);
                            return false;
                        }
                    }
                    return true;
                }, IntPtr.Zero);

                if (chromeHwnd != IntPtr.Zero) {
                    Thread.Sleep(800);
                    // Ctrl+N for new window
                    keybd_event(VK_CONTROL, 0, 0, 0);
                    keybd_event(VK_N, 0, 0, 0);
                    keybd_event(VK_N, 0, KEYEVENTF_KEYUP, 0);
                    keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);

                    Thread.Sleep(1200);
                    SendKeys.SendWait(url);
                    Thread.Sleep(300);
                    SendKeys.SendWait("{ENTER}");
                }

                CloseDesktop(hDefault);
            }
        });
        t.Start();
        t.Join();
    }
}
"@

[ChromeWinController]::OpenNewWindow("http://localhost:5173")
Start-Sleep 3
powershell.exe -ExecutionPolicy Bypass -File .\inspect_windows.ps1
