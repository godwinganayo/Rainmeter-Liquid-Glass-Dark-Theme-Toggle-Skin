# Sets the Windows app + system theme and the matching per-monitor wallpapers.
#   -Light 1 = Light mode, -Light 0 = Dark mode.
param([ValidateSet(0, 1)][int]$Light = 1)

# ---- wallpapers (in .\wallpapers) -----------------------------------
# Landscape monitor = centre, portrait monitor = right.
$wallDir = Join-Path $PSScriptRoot 'wallpapers'
$walls = @{
    0 = @{ Landscape = 'wp3583877-mac-os-desktop-background.jpg'; Portrait = '269540ee-18b7-4d7a-a8b0-a660089a8d52.jpg' }
    1 = @{ Landscape = 'wp4627210-macos-mojave-wallpapers.jpg';    Portrait = '21b52995-edeb-4fcd-9511-dcca85d900e3.jpg' }
}

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace LiquidToggle {
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect { public int Left, Top, Right, Bottom; }

    [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDesktopWallpaper {
        void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
        [return: MarshalAs(UnmanagedType.LPWStr)] string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
        [return: MarshalAs(UnmanagedType.LPWStr)] string GetMonitorDevicePathAt(uint monitorIndex);
        uint GetMonitorDevicePathCount();
        Rect GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
    }

    [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")]
    public class DesktopWallpaperClass { }

    public static class Native {
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
            uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string className, string title);

        const uint WM_SETTINGCHANGE = 0x001A;
        const uint SMTO_ABORTIFHUNG = 0x0002;

        static void Send(IntPtr hWnd, string area) {
            UIntPtr r;
            SendMessageTimeout(hWnd, WM_SETTINGCHANGE, UIntPtr.Zero, area, SMTO_ABORTIFHUNG, 500, out r);
        }

        // Tell every app, then every taskbar explicitly (the secondary-monitor
        // taskbar, Shell_SecondaryTrayWnd, sometimes misses the broadcast).
        public static void NotifyThemeChanged() {
            Send(new IntPtr(0xffff), "ImmersiveColorSet");
            foreach (string cls in new[] { "Shell_TrayWnd", "Shell_SecondaryTrayWnd" }) {
                IntPtr h = IntPtr.Zero;
                while ((h = FindWindowEx(IntPtr.Zero, h, cls, null)) != IntPtr.Zero) {
                    Send(h, "ImmersiveColorSet");
                    Send(h, "TraySettings");
                }
            }
        }

        public static void SetWallpapers(string landscape, string portrait) {
            var dw = (IDesktopWallpaper)new DesktopWallpaperClass();
            uint count = dw.GetMonitorDevicePathCount();
            for (uint i = 0; i < count; i++) {
                string id = dw.GetMonitorDevicePathAt(i);
                Rect r;
                try { r = dw.GetMonitorRECT(id); } catch { continue; }   // monitor not attached
                if (r.Right - r.Left <= 0) continue;
                bool isPortrait = (r.Bottom - r.Top) > (r.Right - r.Left);
                dw.SetWallpaper(id, isPortrait ? portrait : landscape);
            }
        }
    }
}
'@

# Quick double-toggles launch overlapping runs; take turns so the last
# click always wins and wallpapers never end up out of sync with the theme.
$mutex = New-Object System.Threading.Mutex($false, 'Local\LiquidGlassToggle.SetTheme')
try { $owned = $mutex.WaitOne(15000) } catch [System.Threading.AbandonedMutexException] { $owned = $true }

# ---- 1. theme --------------------------------------------------------
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
Set-ItemProperty -Path $key -Name AppsUseLightTheme    -Value $Light -Type DWord
Set-ItemProperty -Path $key -Name SystemUsesLightTheme -Value $Light -Type DWord
[LiquidToggle.Native]::NotifyThemeChanged()

# ---- 2. wallpapers ---------------------------------------------------
$set = $walls[$Light]
$landscape = Join-Path $wallDir $set.Landscape
$portrait  = Join-Path $wallDir $set.Portrait
if ((Test-Path $landscape) -and (Test-Path $portrait)) {
    [LiquidToggle.Native]::SetWallpapers($landscape, $portrait)
}

# ---- 3. second nudge for taskbars that were still repainting ---------
Start-Sleep -Milliseconds 600
[LiquidToggle.Native]::NotifyThemeChanged()

if ($owned) { $mutex.ReleaseMutex() }
