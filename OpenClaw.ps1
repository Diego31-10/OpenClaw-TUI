$ErrorActionPreference = 'Stop'

$script:Theme = @{
    Primary     = [ConsoleColor]::Red
    Dim         = [ConsoleColor]::Red
    Text        = [ConsoleColor]::Gray
    Muted       = [ConsoleColor]::DarkGray
    SelectedFg  = [ConsoleColor]::Black
    SelectedBg  = [ConsoleColor]::Red
    Background  = [ConsoleColor]::Black
}

$script:Tui = @{
    Width  = 80
    Height = 30
    BannerShown = $false
    MainMenuAnimated = $false
    KeepTopMost = $true
}

function Set-CursorVisible {
    param([bool]$Visible)
    try { [Console]::CursorVisible = $Visible } catch {}
}

function Set-Theme {
    try {
        $raw = $Host.UI.RawUI
        $raw.BackgroundColor = $script:Theme.Background
        $raw.ForegroundColor = $script:Theme.Text
        Clear-Host
    } catch {}
}

function Set-WindowTopMost {
    param([bool]$Enable = $true)

    try {
        if (-not ('OpenClawNative.WinApi' -as [type])) {
            Add-Type @"
using System;
using System.Runtime.InteropServices;
namespace OpenClawNative {
    public static class WinApi {
        [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll", SetLastError=true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        [DllImport("user32.dll", SetLastError=true)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
}
"@
        }

        $hWnd = [OpenClawNative.WinApi]::GetConsoleWindow()
        if ($hWnd -ne [IntPtr]::Zero) {
            $HWND_TOPMOST = [IntPtr](-1)
            $HWND_NOTOPMOST = [IntPtr](-2)
            $SWP_NOSIZE = 0x0001
            $SWP_NOMOVE = 0x0002
            $target = if ($Enable) { $HWND_TOPMOST } else { $HWND_NOTOPMOST }
            [OpenClawNative.WinApi]::SetWindowPos($hWnd, $target, 0, 0, 0, 0, ($SWP_NOSIZE -bor $SWP_NOMOVE)) | Out-Null
            if ($Enable) {
                [OpenClawNative.WinApi]::SetForegroundWindow($hWnd) | Out-Null
            }
        }
    } catch {}
}

function Set-ConsoleLayout {
    try {
        $ui = $Host.UI.RawUI
        $largest = $ui.LargestWindowSize

        $targetW = [Math]::Min([Math]::Max($script:Tui.Width, 76), $largest.Width)
        $targetH = [Math]::Min([Math]::Max($script:Tui.Height, 30), $largest.Height)

        if ($ui.BufferSize.Width -lt $targetW) {
            $ui.BufferSize = New-Object System.Management.Automation.Host.Size($targetW, [Math]::Max($ui.BufferSize.Height, $targetH))
        }

        $ui.WindowSize = New-Object System.Management.Automation.Host.Size($targetW, $targetH)

        if ($ui.BufferSize.Width -lt $targetW -or $ui.BufferSize.Height -lt $targetH) {
            $ui.BufferSize = New-Object System.Management.Automation.Host.Size([Math]::Max($targetW, $ui.BufferSize.Width), [Math]::Max($targetH, $ui.BufferSize.Height))
        }
    } catch {}
}

function Get-Pad([int]$contentWidth) {
    $width = $Host.UI.RawUI.WindowSize.Width
    $left = [Math]::Floor(($width - $contentWidth) / 2)
    if ($left -lt 0) { $left = 0 }
    return (' ' * $left)
}

function Write-Footer {
    $footer = 'Made by @Diego31-10'
    Write-Host (Get-Pad $footer.Length) -NoNewline
    Write-Host $footer -ForegroundColor $script:Theme.Muted
}

function Invoke-UiEasingDelay {
    param([int]$Step)
    $curve = @(120, 80, 50, 70, 40, 55, 35, 25)
    if ($Step -lt $curve.Count) {
        Start-Sleep -Milliseconds $curve[$Step]
    } else {
        Start-Sleep -Milliseconds 20
    }
}

function Show-Banner {
    $lines = @(
        ' ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗ ██╗    ██╗',
        '██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗██║    ██║',
        '██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║██║ █╗ ██║',
        '██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║██║███╗██║',
        '╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║╚███╔███╔╝',
        ' ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝'
    )
    
    if ($script:Tui.BannerShown -eq $false) {
        # First time - horizontal reveal + zigzag order without moving final positions.
        try {
            $startTop = [Console]::CursorTop
            $lineLen = $lines[0].Length
            $pad = Get-Pad $lineLen
            $left = $pad.Length

            foreach ($line in $lines) {
                Write-Centered (' ' * $lineLen) $script:Theme.Primary
            }

            $order = @(0, 2, 4, 5, 3, 1)
            $cuts = @(8, 18, 28, 40, 52, 64, 76)

            foreach ($cut in $cuts) {
                foreach ($idx in $order) {
                    $src = $lines[$idx]
                    $visibleLen = [Math]::Min($cut, $src.Length)
                    $frame = $src.Substring(0, $visibleLen).PadRight($src.Length)
                    [Console]::SetCursorPosition($left, $startTop + $idx)
                    Write-Host $frame -ForegroundColor $script:Theme.Primary -NoNewline
                    Start-Sleep -Milliseconds 10
                }
            }

            [Console]::SetCursorPosition(0, $startTop + $lines.Count)
        } catch {
            foreach ($line in $lines) {
                Write-Centered $line $script:Theme.Primary
                Start-Sleep -Milliseconds 30
            }
        }
        $script:Tui.BannerShown = $true
    } else {
        # Subsequent times - show instantly
        foreach ($line in $lines) {
            Write-Centered $line $script:Theme.Primary
        }
    }
}

function Show-BannerFadeIn {
    $lines = @(
        ' ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗ ██╗    ██╗',
        '██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗██║    ██║',
        '██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║██║ █╗ ██║',
        '██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║██║███╗██║',
        '╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║╚███╔███╔╝',
        ' ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝'
    )
    
    foreach ($line in $lines) {
        Write-Centered $line $script:Theme.Primary
        Start-Sleep -Milliseconds 80
    }
}

function Show-Spinner {
    param([int]$DurationMs = 3000)
    $spinners = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $start = Get-Date
    $i = 0
    
    while ((Get-Date) - $start -lt [timespan]::FromMilliseconds($DurationMs)) {
        $spinner = $spinners[$i % $spinners.Count]
        Write-Host "`r  $spinner Loading gateway..." -NoNewline -ForegroundColor $script:Theme.Primary
        Start-Sleep -Milliseconds 100
        $i++
    }
    Write-Host "`r                    " -NoNewline
    # Play beep when loading completes
    Play-Beep
}

function Wait-GatewayOnlineWithSpinner {
    param(
        [string]$Message = 'Starting gateway...',
        [int]$TimeoutSeconds = 35
    )

    $spinners = @('|', '/', '-', '\\')
    $i = 0
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        if ($script:Tui.KeepTopMost) {
            Set-WindowTopMost
        }

        if ((Get-GatewayStatus) -eq 'ONLINE') {
            Write-Host "`r$(' ' * 50)`r" -NoNewline
            Play-Beep
            return $true
        }

        $spinner = $spinners[$i % $spinners.Count]
        Write-Host "`r  $spinner $Message" -NoNewline -ForegroundColor $script:Theme.Primary
        Start-Sleep -Milliseconds 110
        $i++
    }

    Write-Host "`r$(' ' * 50)`r" -NoNewline
    return $false
}

function Wait-GatewayOfflineWithSpinner {
    param(
        [string]$Message = 'Stopping gateway...',
        [int]$TimeoutSeconds = 45
    )

    $spinners = @('|', '/', '-', '\\')
    $i = 0
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        if ($script:Tui.KeepTopMost) {
            Set-WindowTopMost
        }

        if ((Get-GatewayStatus) -eq 'OFFLINE') {
            Write-Host "`r$(' ' * 50)`r" -NoNewline
            Play-Beep
            return $true
        }

        $spinner = $spinners[$i % $spinners.Count]
        Write-Host "`r  $spinner $Message" -NoNewline -ForegroundColor $script:Theme.Primary
        Start-Sleep -Milliseconds 110
        $i++
    }

    Write-Host "`r$(' ' * 50)`r" -NoNewline
    return $false
}

function Start-GatewaySilent {
    try {
        if ((Get-GatewayStatus) -eq 'ONLINE') {
            return $true
        }

        # Launch command detached in hidden PowerShell so this TUI never shows gateway logs.
        Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
            '-NoLogo',
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-Command',
            '& { openclaw gateway start }'
        ) -ErrorAction Stop | Out-Null

        $ok = Wait-GatewayOnlineWithSpinner -Message 'Starting gateway...' -TimeoutSeconds 75
        if (-not $ok) {
            Write-Centered 'Gateway start command sent. Waiting for ONLINE state...' $script:Theme.Muted
            return $true
        }

        return $true
    } catch {
        Write-Centered "Error starting gateway: $($_.Exception.Message)" Red
        return $false
    }
}

function Stop-GatewaySilent {
    try {
        if ((Get-GatewayStatus) -eq 'OFFLINE') {
            return $true
        }

        # Match start strategy: detached hidden PowerShell process.
        Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
            '-NoLogo',
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-Command',
            '& { openclaw gateway stop }'
        ) -ErrorAction Stop | Out-Null

        $ok = Wait-GatewayOfflineWithSpinner -Message 'Stopping gateway...' -TimeoutSeconds 45
        if (-not $ok) {
            Write-Centered 'Gateway stop command sent. Waiting for OFFLINE state...' $script:Theme.Muted
            return $true
        }

        return $true
    } catch {
        Write-Centered "Error stopping gateway: $($_.Exception.Message)" Red
        return $false
    }
}

function Play-Beep {
    try {
        [Console]::Beep(800, 150)
        Start-Sleep -Milliseconds 100
        [Console]::Beep(1000, 150)
    } catch {}
}

function Write-Centered {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [ConsoleColor]$ForegroundColor = $script:Theme.Text,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black
    )
    $pad = Get-Pad $Text.Length
    Write-Host ($pad + $Text) -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

function Write-CenteredPair {
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right,
        [ConsoleColor]$LeftColor = $script:Theme.Text,
        [ConsoleColor]$RightColor = $script:Theme.Text,
        [ConsoleColor]$LeftBg = [ConsoleColor]::Black,
        [ConsoleColor]$RightBg = [ConsoleColor]::Black
    )

    $total = $Left.Length + 2 + $Right.Length
    $pad = Get-Pad $total

    Write-Host $pad -NoNewline
    Write-Host $Left -ForegroundColor $LeftColor -BackgroundColor $LeftBg -NoNewline
    Write-Host '  ' -NoNewline
    Write-Host $Right -ForegroundColor $RightColor -BackgroundColor $RightBg
}

function Read-Key {
    return [Console]::ReadKey($true)
}

function Wait-AnyKey {
    param([string]$Message = 'Press any key to continue...')
    Write-Host ''
    Write-Centered $Message $script:Theme.Primary
    [void](Read-Key)
}

function Read-TextInput {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [switch]$Mask
    )

    $sb = New-Object System.Text.StringBuilder
    $promptLine = "  $Prompt > "
    [Console]::Write($promptLine)

    while ($true) {
        $key = Read-Key

        if ($key.Key -eq [ConsoleKey]::Enter) { break }

        if ($key.Key -eq [ConsoleKey]::Backspace) {
            if ($sb.Length -gt 0) {
                $sb.Length = $sb.Length - 1
                [Console]::Write("`b `b")
            }
            continue
        }

        if (-not [char]::IsControl($key.KeyChar)) {
            [void]$sb.Append($key.KeyChar)
            if ($Mask) { [Console]::Write('*') } else { [Console]::Write($key.KeyChar) }
        }
    }

    Write-Host ''
    return $sb.ToString()
}

function Invoke-OpenClaw {
    param([Parameter(Mandatory = $true)][string[]]$Args)
    try {
        & openclaw @Args
    } catch {
        Write-Centered "Error running openclaw $($Args -join ' '): $($_.Exception.Message)" Red
    }
}

function Get-GatewayStatus {
    try {
        # Preferred on Windows: direct TCP state check (language independent)
        if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
            $conn = Get-NetTCPConnection -LocalPort 18789 -State Listen -ErrorAction SilentlyContinue
            if ($conn) { return 'ONLINE' }
        }
    } catch {}

    try {
        # Fallback for environments without Get-NetTCPConnection.
        $lines = netstat -ano 2>$null | Select-String ':18789'
        if ($lines) {
            foreach ($line in $lines) {
                if ($line -match '(LISTENING|ESCUCHANDO)') {
                    return 'ONLINE'
                }
            }
        }
    } catch {}

    return 'OFFLINE'
}

function Get-RandomTip {
    $tips = @(
        'Doctor can run a full system health check.',
        'Gateway start opens in a separate window.',
        'Use Neural Manager to check model status quickly.',
        'Paste your token in Neural Manager to enable models.',
        'Skills Update keeps your modules in sync.',
        'Web Dashboard gives a quick visual status view.',
        'Onboarding helps you reconfigure safely.'
    )
    return $tips[(Get-Random -Minimum 0 -Maximum $tips.Count)]
}

function Get-MainTip {
    param([int]$Selected)

    $tips = @(
        'Gateway panel: start, stop, or restart your local gateway.',
        'Neural Manager: verify model status and provider auth quickly.',
        'Skills Modules: search and update skills from ClawHub.',
        'Web Dashboard: open localhost 18789 in your default browser.',
        'Support & Doctor: run diagnostics and onboarding workflows.',
        'Exit closes the TUI and restores the terminal cursor.'
    )

    if ($Selected -lt 0 -or $Selected -ge $tips.Count) {
        return $tips[0]
    }

    return $tips[$Selected]
}

function Fit-Field {
    param([string]$Text, [int]$Width)
    if ($Text.Length -gt $Width) { return $Text.Substring(0, $Width) }
    return $Text.PadRight($Width)
}

function New-Card {
    param(
        [string]$Title,
        [string]$Subtitle,
        [bool]$Selected
    )

    $inner = 34
    $marker = if ($Selected) { '▶' } else { ' ' }
    $titleText = ("$marker $Title").PadRight($inner)
    $subText = ("  $Subtitle").PadRight($inner)

    return [pscustomobject]@{
        Top      = ('┏' + ('━' * $inner) + '┓')
        Bottom   = ('┗' + ('━' * $inner) + '┛')
        InnerW   = $inner
        Title    = $titleText
        Subtitle = $subText
        Fg       = if ($Selected) { $script:Theme.SelectedFg } else { $script:Theme.Text }
        Bg       = if ($Selected) { [ConsoleColor]::Red } else { [ConsoleColor]::Black }
        SubFg    = if ($Selected) { $script:Theme.SelectedFg } else { $script:Theme.Muted }
        SubBg    = if ($Selected) { [ConsoleColor]::Red } else { [ConsoleColor]::Black }
    }
}

function Write-CardRowPair {
    param(
        [pscustomobject]$Left,
        [pscustomobject]$Right,
        [string]$Field
    )

    $leftText = $Left.$Field
    $rightText = $Right.$Field
    $total = ($Left.InnerW + 2) + 2 + ($Right.InnerW + 2)
    $pad = Get-Pad $total

    Write-Host $pad -NoNewline

    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline
    Write-Host $leftText -ForegroundColor $Left.Fg -BackgroundColor $Left.Bg -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline

    Write-Host '  ' -NoNewline

    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline
    Write-Host $rightText -ForegroundColor $Right.Fg -BackgroundColor $Right.Bg -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim
}

function Write-CardSubRowPair {
    param(
        [pscustomobject]$Left,
        [pscustomobject]$Right
    )

    $total = ($Left.InnerW + 2) + 2 + ($Right.InnerW + 2)
    $pad = Get-Pad $total

    Write-Host $pad -NoNewline

    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline
    Write-Host $Left.Subtitle -ForegroundColor $Left.SubFg -BackgroundColor $Left.SubBg -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline

    Write-Host '  ' -NoNewline

    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline
    Write-Host $Right.Subtitle -ForegroundColor $Right.SubFg -BackgroundColor $Right.SubBg -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim
}

function Draw-MainMenu {
    param(
        [string]$GatewayStatus,
        [int]$Selected
    )

    $node = Fit-Field "$env:USERNAME@$env:COMPUTERNAME" 20
    $date = (Get-Date).ToString('yyyy-MM-dd')
    $gw = if ($GatewayStatus -eq 'ONLINE') { 'ONLINE ' } else { 'OFFLINE' }

    $items = @(
        @{ Title = 'GATEWAY CONTROL'; Subtitle = 'Start / Stop / Restart' },
        @{ Title = 'NEURAL MANAGER'; Subtitle = 'Auth / Tokens / Status' },
        @{ Title = 'SKILLS MODULES'; Subtitle = 'ClawHub / Marketplace' },
        @{ Title = 'WEB DASHBOARD'; Subtitle = 'Localhost :18789' },
        @{ Title = 'SUPPORT & DOCTOR'; Subtitle = 'Onboarding / Diagnose' },
        @{ Title = 'EXIT'; Subtitle = 'Close terminal' }
    )

    $leftTop = New-Card -Title $items[0].Title -Subtitle $items[0].Subtitle -Selected ($Selected -eq 0)
    $leftMid = New-Card -Title $items[1].Title -Subtitle $items[1].Subtitle -Selected ($Selected -eq 1)
    $leftBot = New-Card -Title $items[2].Title -Subtitle $items[2].Subtitle -Selected ($Selected -eq 2)
    $rightTop = New-Card -Title $items[3].Title -Subtitle $items[3].Subtitle -Selected ($Selected -eq 3)
    $rightMid = New-Card -Title $items[4].Title -Subtitle $items[4].Subtitle -Selected ($Selected -eq 4)
    $rightBot = New-Card -Title $items[5].Title -Subtitle $items[5].Subtitle -Selected ($Selected -eq 5)

    $animate = -not $script:Tui.MainMenuAnimated
    $animStep = 0

    Clear-Host
    Write-Host ''
    Show-Banner
    Write-Host ''
    if ($animate) { Invoke-UiEasingDelay $animStep; $animStep++ }

    $tip = Get-MainTip -Selected $Selected
    Write-Centered $tip $script:Theme.Muted
    Write-Host ''
    if ($animate) { Invoke-UiEasingDelay $animStep; $animStep++ }

    $statusInner = 66
    $statusTop = '┏' + ('━' * $statusInner) + '┓'
    $nodeField = Fit-Field (' NODE ' + $node) 22
    $gwField = Fit-Field (' GATEWAY ' + $gw) 22
    $dateField = Fit-Field (' DATE ' + $date) 22
    $statusContent = ($nodeField + $gwField + $dateField)
    $statusBot = '┗' + ('━' * $statusInner) + '┛'

    Write-Centered $statusTop $script:Theme.Dim
    Write-Host (Get-Pad ($statusInner + 2)) -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline
    Write-Host $statusContent -ForegroundColor $script:Theme.Text -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim
    Write-Centered $statusBot $script:Theme.Dim
    Write-Host ''
    if ($animate) { Invoke-UiEasingDelay $animStep; $animStep++ }

    # Keep visual intro effects but preserve strict top/middle/bottom layout order.
    Write-CenteredPair -Left $leftTop.Top -Right $rightTop.Top -LeftColor $script:Theme.Dim -RightColor $script:Theme.Dim
    Write-CardRowPair -Left $leftTop -Right $rightTop -Field 'Title'
    Write-CardSubRowPair -Left $leftTop -Right $rightTop
    Write-CenteredPair -Left $leftTop.Bottom -Right $rightTop.Bottom -LeftColor $script:Theme.Dim -RightColor $script:Theme.Dim
    if ($animate) { Invoke-UiEasingDelay $animStep; $animStep++ }

    Write-CenteredPair -Left $leftMid.Top -Right $rightMid.Top -LeftColor $script:Theme.Dim -RightColor $script:Theme.Dim
    Write-CardRowPair -Left $leftMid -Right $rightMid -Field 'Title'
    Write-CardSubRowPair -Left $leftMid -Right $rightMid
    Write-CenteredPair -Left $leftMid.Bottom -Right $rightMid.Bottom -LeftColor $script:Theme.Dim -RightColor $script:Theme.Dim
    if ($animate) { Invoke-UiEasingDelay $animStep; $animStep++ }

    Write-CenteredPair -Left $leftBot.Top -Right $rightBot.Top -LeftColor $script:Theme.Dim -RightColor $script:Theme.Dim
    Write-CardRowPair -Left $leftBot -Right $rightBot -Field 'Title'
    Write-CardSubRowPair -Left $leftBot -Right $rightBot
    Write-CenteredPair -Left $leftBot.Bottom -Right $rightBot.Bottom -LeftColor $script:Theme.Dim -RightColor $script:Theme.Dim
    if ($animate) { Invoke-UiEasingDelay $animStep; $animStep++ }

    Write-Host ''
    Write-Centered 'W A S D move  ENTER select' $script:Theme.Primary
    Write-Host ''
    Write-Footer

    if ($animate) {
        $script:Tui.MainMenuAnimated = $true
    }
}

function Read-MainMenuSelection {
    $selected = 0
    while ($true) {
        Draw-MainMenu -GatewayStatus (Get-GatewayStatus) -Selected $selected
        $key = Read-Key

        if ($key.Key -eq [ConsoleKey]::Enter) { return $selected }

        $ch = ([string]$key.KeyChar).ToUpperInvariant()
        switch ($ch) {
            'W' { if ($selected -in 1,2,4,5) { $selected -= 1 } }
            'S' { if ($selected -in 0,1,3,4) { $selected += 1 } }
            'A' { if ($selected -ge 3) { $selected -= 3 } }
            'D' { if ($selected -le 2) { $selected += 3 } }
        }
    }
}

function Read-ListSelection {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string[]]$Items,
        [string]$Footer = 'W/S move  ENTER select'
    )

    $selected = 0
    $inner = 54
    $animated = $false

    while ($true) {
        Clear-Host
        Write-Host ''
        Write-Centered $Title $script:Theme.Primary
        Write-Host ''

        $animate = -not $animated
        $animStep = 0
        if ($animate) { Invoke-UiEasingDelay $animStep; $animStep++ }

        $top = '┏' + ('━' * $inner) + '┓'
        $bottom = '┗' + ('━' * $inner) + '┛'
        Write-Centered $top $script:Theme.Dim

        for ($i = 0; $i -lt $Items.Count; $i++) {
            $isSel = ($i -eq $selected)
            $marker = if ($isSel) { '▶' } else { ' ' }
            $text = ("$marker " + $Items[$i]).PadRight($inner)
            $pad = Get-Pad ($inner + 2)
            Write-Host $pad -NoNewline
            Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline
            if ($isSel) {
                Write-Host $text -ForegroundColor $script:Theme.Primary -BackgroundColor Black -NoNewline
            } else {
                Write-Host $text -ForegroundColor $script:Theme.Text -BackgroundColor Black -NoNewline
            }
            Write-Host '┃' -ForegroundColor $script:Theme.Dim
        }
        if ($animate) { Invoke-UiEasingDelay $animStep; $animStep++ }

        Write-Centered $bottom $script:Theme.Dim
        Write-Host ''
        Write-Centered $Footer $script:Theme.Primary
        Write-Host ''
        Write-Footer

        if ($animate) {
            $animated = $true
        }

        $key = Read-Key
        if ($key.Key -eq [ConsoleKey]::Enter) { return $selected }

        $ch = ([string]$key.KeyChar).ToUpperInvariant()
        switch ($ch) {
            'W' {
                $selected--
                if ($selected -lt 0) { $selected = $Items.Count - 1 }
            }
            'S' {
                $selected++
                if ($selected -ge $Items.Count) { $selected = 0 }
            }
        }
    }
}

function Show-GatewayMenu {
    while ($true) {
        $status = Get-GatewayStatus
        $choice = Read-ListSelection -Title "GATEWAY CONTROL   STATUS: $status" -Items @(
            'Start Gateway',
            'Stop Gateway',
            'Restart Gateway',
            'Back to Main Menu'
        )

        switch ($choice) {
            0 {
                Clear-Host
                Write-Centered 'Starting gateway...' $script:Theme.Primary
                Write-Host ''
                [void](Start-GatewaySilent)
                Write-Host ''
                Write-Centered ("Gateway status: $(Get-GatewayStatus)") $script:Theme.Muted
                Wait-AnyKey
            }
            1 {
                Clear-Host
                Write-Centered 'Stopping gateway...' $script:Theme.Primary
                Write-Host ''
                [void](Stop-GatewaySilent)
                Write-Host ''
                Write-Centered ("Gateway status: $(Get-GatewayStatus)") $script:Theme.Muted
                Wait-AnyKey
            }
            2 {
                Clear-Host
                Write-Centered 'Restarting gateway...' $script:Theme.Primary
                Write-Host ''
                Invoke-OpenClaw -Args @('gateway', 'restart')
                Show-Spinner -DurationMs 3000
                Write-Host ''
                Write-Centered ("Gateway status: $(Get-GatewayStatus)") $script:Theme.Muted
                Wait-AnyKey
            }
            3 { return }
        }
    }
}

function Show-NeuralMenu {
    while ($true) {
        $choice = Read-ListSelection -Title 'NEURAL MANAGER' -Items @(
            'Model Status',
            'Paste Anthropic Token',
            'Back to Main Menu'
        )

        switch ($choice) {
            0 {
                Clear-Host
                Invoke-OpenClaw -Args @('models', 'status')
                Wait-AnyKey
            }
            1 {
                $tok = Read-TextInput -Prompt 'Token' -Mask
                if (-not [string]::IsNullOrWhiteSpace($tok)) {
                    Invoke-OpenClaw -Args @('models', 'auth', 'paste-token', '--provider', 'anthropic', $tok)
                    Write-Centered 'Token registered.' $script:Theme.Primary
                } else {
                    Write-Centered 'Empty token, no changes.' $script:Theme.Muted
                }
                Wait-AnyKey
            }
            2 { return }
        }
    }
}

function Show-SkillsMenu {
    while ($true) {
        $choice = Read-ListSelection -Title 'SKILLS MODULES' -Items @(
            'Search skill on ClawHub',
            'Update all skills',
            'List installed skills',
            'Back to Main Menu'
        )

        switch ($choice) {
            0 {
                $skill = Read-TextInput -Prompt 'Skill'
                if (-not [string]::IsNullOrWhiteSpace($skill)) {
                    try {
                        & clawdhub search $skill
                    } catch {
                        Write-Centered "Error running clawdhub search: $($_.Exception.Message)" Red
                    }
                } else {
                    Write-Centered 'Empty search.' $script:Theme.Muted
                }
                Wait-AnyKey
            }
            1 {
                Clear-Host
                Write-Centered 'Updating all skills...' $script:Theme.Primary
                Invoke-OpenClaw -Args @('skills', 'update')
                Wait-AnyKey
            }
            2 {
                Clear-Host
                Invoke-OpenClaw -Args @('skills', 'list')
                Wait-AnyKey
            }
            3 { return }
        }
    }
}

function Show-SupportMenu {
    while ($true) {
        $choice = Read-ListSelection -Title "SUPPORT & DOCTOR" -Items @(
            'Doctor -- full diagnostic',
            'Onboarding -- setup wizard',
            'Back to Main Menu'
        )

        switch ($choice) {
            0 {
                Clear-Host
                Invoke-OpenClaw -Args @('doctor', '--non-interactive')
                Wait-AnyKey
            }
            1 {
                Clear-Host
                Invoke-OpenClaw -Args @('onboard')
                Wait-AnyKey
            }
            2 { return }
        }
    }
}

function Open-Dashboard {
    $status = Get-GatewayStatus
    Clear-Host
    if ($status -ne 'ONLINE') {
        Write-Centered 'Gateway is OFFLINE' $script:Theme.Primary
        Write-Centered 'Web Dashboard requires gateway to be online.' $script:Theme.Muted
    } else {
        Write-Centered 'Opening dashboard: http://127.0.0.1:18789/' $script:Theme.Primary
        Start-Process 'http://127.0.0.1:18789/' | Out-Null
    }
    Wait-AnyKey
}

function Show-Exit {
    Clear-Host
    Write-Host ''
    $inner = 36
    $top = '┏' + ('━' * $inner) + '┓'
    $bot = '┗' + ('━' * $inner) + '┛'

    $line1 = ' OpenClaw closed successfully. '
    $line2 = (" Goodbye, {0}. " -f $env:USERNAME)

    if ($line1.Length -gt $inner) { $line1 = $line1.Substring(0, $inner) }
    if ($line2.Length -gt $inner) { $line2 = $line2.Substring(0, $inner) }

    $line1 = $line1.PadRight($inner)
    $line2 = $line2.PadRight($inner)

    $pad = Get-Pad ($inner + 2)

    Write-Centered $top $script:Theme.Dim

    Write-Host $pad -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline
    Write-Host $line1 -ForegroundColor $script:Theme.Primary -BackgroundColor $script:Theme.Background -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim

    Write-Host $pad -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim -NoNewline
    Write-Host $line2 -ForegroundColor $script:Theme.Muted -BackgroundColor $script:Theme.Background -NoNewline
    Write-Host '┃' -ForegroundColor $script:Theme.Dim

    Write-Centered $bot $script:Theme.Dim
    Write-Host ''
    Write-Centered "Made by @Diego31-10" $script:Theme.Muted
    Start-Sleep -Seconds 1.5
    exit
}

Set-Theme
Set-ConsoleLayout
Set-WindowTopMost
Set-CursorVisible $false

try {
    while ($true) {
        $sel = Read-MainMenuSelection
        switch ($sel) {
            0 { Show-GatewayMenu }
            1 { Show-NeuralMenu }
            2 { Show-SkillsMenu }
            3 { Open-Dashboard }
            4 { Show-SupportMenu }
            5 { Show-Exit; break }
        }
    }
} finally {
    Set-CursorVisible $true
}
