Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Text;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class ForegroundUnicodeLogin {
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
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr ProcessId);

    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool CloseDesktop(IntPtr hDesktop);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);

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

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT {
        public int type;
        public MOUSEKEYBDHARDWAREINPUT mkhi;
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct MOUSEKEYBDHARDWAREINPUT {
        [FieldOffset(0)]
        public KEYBDINPUT ki;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    public const uint KEYEVENTF_UNICODE = 0x0004;
    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP   = 0x0004;

    public static void ForceForeground(IntPtr hWnd) {
        IntPtr foreWin = GetForegroundWindow();
        uint foreThread = GetWindowThreadProcessId(foreWin, IntPtr.Zero);
        uint myThread = GetCurrentThreadId();
        if (foreThread != myThread && foreThread != 0) {
            AttachThreadInput(myThread, foreThread, true);
            ShowWindow(hWnd, 3);
            SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 1280, 800, 0x0040);
            SetForegroundWindow(hWnd);
            AttachThreadInput(myThread, foreThread, false);
        } else {
            ShowWindow(hWnd, 3);
            SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 1280, 800, 0x0040);
            SetForegroundWindow(hWnd);
        }
    }

    public static void SendKeyVk(ushort vk) {
        INPUT[] inputs = new INPUT[2];
        inputs[0].type = 1;
        inputs[0].mkhi.ki.wVk = vk;
        inputs[0].mkhi.ki.dwFlags = 0;

        inputs[1].type = 1;
        inputs[1].mkhi.ki.wVk = vk;
        inputs[1].mkhi.ki.dwFlags = KEYEVENTF_KEYUP;

        SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
        Thread.Sleep(50);
    }

    public static void TypeString(string text) {
        foreach (char c in text) {
            INPUT[] inputs = new INPUT[2];
            inputs[0].type = 1;
            inputs[0].mkhi.ki.wVk = 0;
            inputs[0].mkhi.ki.wScan = (ushort)c;
            inputs[0].mkhi.ki.dwFlags = KEYEVENTF_UNICODE;

            inputs[1].type = 1;
            inputs[1].mkhi.ki.wVk = 0;
            inputs[1].mkhi.ki.wScan = (ushort)c;
            inputs[1].mkhi.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;

            SendInput(2, inputs, Marshal.SizeOf(typeof(INPUT)));
            Thread.Sleep(30);
        }
    }

    public static void DoLoginAndCapture(string outPath) {
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
                        ForceForeground(hWnd);
                        return false;
                    }
                }
                return true;
            }, IntPtr.Zero);

            if (reactWin != IntPtr.Zero) {
                Thread.Sleep(800);

                // Dismiss tooltip with Escape
                SendKeyVk(0x1B);
                Thread.Sleep(200);

                // Scroll to top
                SendKeyVk(0x24);
                Thread.Sleep(300);

                // Page down
                SendKeyVk(0x22);
                Thread.Sleep(500);

                // Click email field
                SetCursorPos(400, 690);
                Thread.Sleep(100);
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
                Thread.Sleep(50);
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
                Thread.Sleep(300);

                // Clear email
                INPUT[] selectAll = new INPUT[4];
                selectAll[0].type = 1; selectAll[0].mkhi.ki.wVk = 0x11; selectAll[0].mkhi.ki.dwFlags = 0;
                selectAll[1].type = 1; selectAll[1].mkhi.ki.wVk = 0x41; selectAll[1].mkhi.ki.dwFlags = 0;
                selectAll[2].type = 1; selectAll[2].mkhi.ki.wVk = 0x41; selectAll[2].mkhi.ki.dwFlags = KEYEVENTF_KEYUP;
                selectAll[3].type = 1; selectAll[3].mkhi.ki.wVk = 0x11; selectAll[3].mkhi.ki.dwFlags = KEYEVENTF_KEYUP;
                SendInput(4, selectAll, Marshal.SizeOf(typeof(INPUT)));
                Thread.Sleep(100);
                SendKeyVk(0x08);
                Thread.Sleep(200);

                // Type email
                TypeString("docker_test@example.com");
                Thread.Sleep(300);

                // Tab to password
                SendKeyVk(0x09);
                Thread.Sleep(300);

                // Clear password
                SendInput(4, selectAll, Marshal.SizeOf(typeof(INPUT)));
                Thread.Sleep(100);
                SendKeyVk(0x08);
                Thread.Sleep(200);

                // Type password
                TypeString("password123");
                Thread.Sleep(300);

                // Submit
                SendKeyVk(0x0D);

                // Wait 4 seconds for backend login and redirection to /projects
                Thread.Sleep(4000);

                // Scroll to top
                SendKeyVk(0x24);
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

$target = "C:\Users\Ayush\Downloads\Practical11_Screenshots\09_Browser_Task_CRUD.png"
[ForegroundUnicodeLogin]::DoLoginAndCapture($target)
Write-Host "09 Result: $(Test-Path $target) ($( (Get-Item $target).Length ) bytes)"
