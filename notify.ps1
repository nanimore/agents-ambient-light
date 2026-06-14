param([string]$event = "stop")

# ── Load config from YAML ────────────────────────────
$configPath = "$env:USERPROFILE/.claude/ambient-light-config.yaml"
$config = @{}
$enableOverlay = $true
$enableSound = $true
$enableFlash = $true
$overlayColor = "red"
$overlayStyle = "border"
$overlayAnimation = "breathe"
$overlayDuration = 3
$overlayWidth = 10
$overlayAlpha = 0.6

if (Test-Path $configPath) {
    $content = Get-Content $configPath -Raw
    # 简易 YAML 解析（仅解析我们需要的字段）
    if ($content -match 'enable_overlay:\s*(\w+)') { $enableOverlay = $matches[1] -eq 'true' }
    if ($content -match 'enable_sound:\s*(\w+)') { $enableSound = $matches[1] -eq 'true' }
    if ($content -match 'enable_flash:\s*(\w+)') { $enableFlash = $matches[1] -eq 'true' }
    if ($content -match "style:\s*(\w+)") { $overlayStyle = $matches[1] }
    if ($content -match "animation:\s*(\w+)") { $overlayAnimation = $matches[1] }
    if ($content -match "duration:\s*(\d+)") { $overlayDuration = [int]$matches[1] }
    if ($content -match "width:\s*(\d+)") { $overlayWidth = [int]$matches[1] }
    if ($content -match "alpha:\s*([\d.]+)") { $overlayAlpha = [double]$matches[1] }

    # 解析事件颜色
    if ($content -match "$event`:\s*color:\s*(\w+)") {
        $overlayColor = $matches[1]
    }
}

# ── Configure sounds per event ───────────────────────
$stopSound = 2           # Claude finished responding (chimes)
$inputSound = 3          # permission prompt, question (Windows exclamation)
$taskCompleteSound = 1   # task marked complete (ding)
$subagentStopSound = 0   # subagent finished (off, otherwise may trigger after stop)

# ── Configure taskbar flash per event ────────────────
# $true = flash taskbar icon, $false = no flash
$stopFlash = $true
$inputFlash = $true

# ── Sound options (indexed subtle → loud) ─────────
# 0 = off (no sound)
# 1 = ding.wav
# 2 = chimes.wav
# 3 = Windows Exclamation.wav
# 4 = notify.wav
# 5 = chord.wav
# 6 = Windows Proximity Notification.wav
# 7 = tada.wav

# ── Resolve which sound & flash to use ───────────────
$soundMap = @{
    1 = "ding.wav"
    2 = "chimes.wav"
    3 = "Windows Exclamation.wav"
    4 = "notify.wav"
    5 = "chord.wav"
    6 = "Windows Proximity Notification.wav"
    7 = "tada.wav"
}

$soundIndex = switch ($event) {
    "input" { $inputSound }
    "subagent_stop" { $subagentStopSound }
    "task_complete" { $taskCompleteSound }
    default { $stopSound }
}

$flashEnabled = switch ($event) {
    "stop" { $stopFlash }
    "input" { $inputFlash }
    default { $false }
}

# ── Nothing to do ────────────────────────────────────
if (-not $enableOverlay -and -not $enableSound -and -not $enableFlash) { exit }
if ($soundIndex -eq 0 -and -not $flashEnabled -and -not $enableOverlay) { exit }

# ── Launch ambient light overlay ─────────────────────
if ($enableOverlay) {
    $pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
    if ($pythonPath) {
        $ambientLightPath = "$env:USERPROFILE/.claude/ambient-light-qt.py"  # 使用 Qt 版本
        if (Test-Path $ambientLightPath) {
            # 后台启动 Python 脚本（不阻塞声音和闪烁）
            Start-Process -FilePath $pythonPath `
                -ArgumentList "$ambientLightPath","--color",$overlayColor,"--duration",$overlayDuration,"--style",$overlayStyle,"--animation",$overlayAnimation,"--width",$overlayWidth,"--alpha",$overlayAlpha `
                -WindowStyle Hidden `
                -NoNewWindow:$false
        }
    }
}

# ── Play sound ───────────────────────────────────────
if ($enableSound -and $soundIndex -ne 0) {
    $file = $soundMap[$soundIndex]
    (New-Object Media.SoundPlayer "C:\Windows\Media\$file").PlaySync()
}

# ── Flash taskbar icon ───────────────────────────────
if ($enableFlash -and $flashEnabled) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public struct FLASHWINFO {
    public uint cbSize;
    public IntPtr hwnd;
    public uint dwFlags;
    public uint uCount;
    public uint dwTimeout;
}

public static class FlashWindow {
    [DllImport("user32.dll")]
    public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hwnd);

    public static void Flash(IntPtr hwnd, uint count) {
        if (hwnd == GetForegroundWindow()) return;

        FLASHWINFO fw = new FLASHWINFO();
        fw.cbSize = (uint)Marshal.SizeOf(typeof(FLASHWINFO));
        fw.hwnd = hwnd;
        fw.dwFlags = 3;  // FLASHW_ALL (caption + taskbar)
        fw.uCount = count;
        fw.dwTimeout = 0;  // use default cursor blink rate
        FlashWindowEx(ref fw);
    }
}
"@

    # Build a pid→parentPid lookup from a single WMI call, then walk up the
    # process tree to find the nearest ancestor with a visible window.
    # Works universally: VS Code, Windows Terminal, cmd, PowerShell, any embedded terminal.
    $parentOf = @{}
    Get-CimInstance Win32_Process -Property ProcessId,ParentProcessId |
        ForEach-Object { $parentOf[[int]$_.ProcessId] = [int]$_.ParentProcessId }

    $hwnd = [IntPtr]::Zero
    $id = $PID
    while ($id -and $id -ne 0) {
        $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
        if ($proc) {
            $h = $proc.MainWindowHandle
            if ($h -ne [IntPtr]::Zero -and [FlashWindow]::IsWindowVisible($h)) {
                $hwnd = $h
                break
            }
        }
        $id = $parentOf[$id]
    }

    if ($hwnd -ne [IntPtr]::Zero) {
        [FlashWindow]::Flash($hwnd, 3)
    }
}
