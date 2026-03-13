$csharpCode = @"
using System;
using System.Runtime.InteropServices;

public class WinAPI_Ultimate {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumChildWindows(IntPtr hWndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware(); 

    public static void ToggleFullscreen(IntPtr hwnd) {
        SetProcessDPIAware();

        int GWL_STYLE = -16;
        int WS_CAPTION = 0x00C00000;
        int WS_THICKFRAME = 0x00040000;
        int WS_BORDER = 0x00800000;
        int WS_POPUP = unchecked((int)0x80000000); 
        
        int GWL_EXSTYLE = -20;
        int WS_EX_CLIENTEDGE = 0x00000200;
        int WS_EX_WINDOWEDGE = 0x00000100;
        
        uint SWP_FRAMECHANGED = 0x0020;
        uint SWP_NOZORDER = 0x0004;

        int currentStyle = GetWindowLong(hwnd, GWL_STYLE);
        int currentExStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
        
        bool isFullscreen = (currentStyle & WS_POPUP) != 0;

        int width = GetSystemMetrics(0); 
        int height = GetSystemMetrics(1);

        if (!isFullscreen) {
            int newStyle = (currentStyle & ~WS_CAPTION & ~WS_THICKFRAME & ~WS_BORDER) | WS_POPUP;
            SetWindowLong(hwnd, GWL_STYLE, newStyle);
            
            int newExStyle = currentExStyle & ~WS_EX_CLIENTEDGE & ~WS_EX_WINDOWEDGE;
            SetWindowLong(hwnd, GWL_EXSTYLE, newExStyle);

            SetWindowPos(hwnd, IntPtr.Zero, 0, 0, width, height, SWP_FRAMECHANGED);

            EnumChildWindows(hwnd, (childHwnd, lParam) => {
                RECT rect;
                if (GetWindowRect(childHwnd, out rect)) {
                    int h = rect.Bottom - rect.Top;
                    if (h > 0 && h < 60) {
                        ShowWindow(childHwnd, 0);
                    } else if (h > 100) {
                        SetWindowPos(childHwnd, IntPtr.Zero, 0, 0, width, height, SWP_NOZORDER);
                    }
                }
                return true;
            }, IntPtr.Zero);
            
        } else {
            int newStyle = (currentStyle & ~WS_POPUP) | WS_CAPTION | WS_THICKFRAME | WS_BORDER;
            SetWindowLong(hwnd, GWL_STYLE, newStyle);
            
            SetWindowPos(hwnd, IntPtr.Zero, 100, 100, 1024, 768, SWP_FRAMECHANGED);

            EnumChildWindows(hwnd, (childHwnd, lParam) => {
                RECT rect;
                if (GetWindowRect(childHwnd, out rect)) {
                    int h = rect.Bottom - rect.Top;
                    if (h > 0 && h < 60) {
                        ShowWindow(childHwnd, 5);
                    }
                }
                return true;
            }, IntPtr.Zero);
        }
    }
}
"@

Add-Type -TypeDefinition $csharpCode -ErrorAction Stop

$vmProcess = Get-Process -Name "vmconnect" -ErrorAction SilentlyContinue

if ($vmProcess) {
    $hwnd = $vmProcess[0].MainWindowHandle
    [WinAPI_Ultimate]::ToggleFullscreen($hwnd)
    Write-Host "Done, vmconnect.exe ignored DPI and top most on 'fullscreen'" -ForegroundColor Green
} else {
    Write-Host "vmconnect.exe not found" -ForegroundColor Red
}