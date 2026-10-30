Add-Type @"
using System;
using System.Text;
using System.Threading;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class WinInspector2 {
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
    public static extern bool CloseDesktop(IntPtr hDesktop);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    public static void List() {
        Thread t = new Thread(() => {
            IntPtr hDefault = OpenDesktop("Default", 0, false, 0x01FF);
            if (hDefault != IntPtr.Zero) {
                SetThreadDesktop(hDefault);
                EnumDesktopWindows(hDefault, (hWnd, lParam) => {
                    if (IsWindowVisible(hWnd)) {
                        StringBuilder sb = new StringBuilder(256);
                        GetWindowText(hWnd, sb, 256);
                        string title = sb.ToString();
                        if (!string.IsNullOrWhiteSpace(title)) {
                            uint pid = 0;
                            GetWindowThreadProcessId(hWnd, out pid);
                            string procName = "unknown";
                            try {
                                procName = Process.GetProcessById((int)pid).ProcessName;
                            } catch {}
                            Console.WriteLine(hWnd + " (PID: " + pid + ", " + procName + ") : " + title);
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
}
"@

[WinInspector2]::List()
