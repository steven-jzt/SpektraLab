# SpektraLab 免管理员安装脚本
# 复制到 %LOCALAPPDATA%\SpektraLab，并在桌面与开始菜单创建快捷方式。
$ErrorActionPreference = 'Stop'

$src = $PSScriptRoot
$dst = Join-Path $env:LOCALAPPDATA 'SpektraLab'

Write-Host 'SpektraLab 安装程序' -ForegroundColor Cyan
Write-Host "  从: $src"
Write-Host "  到: $dst"
Write-Host ''

if (-not (Test-Path (Join-Path $src 'spektralab.exe'))) {
    Write-Host '找不到 spektralab.exe，请先完整解压压缩包再运行本脚本。' -ForegroundColor Red
    exit 1
}

$running = Get-Process spektralab -ErrorAction SilentlyContinue
if ($running) {
    Write-Host '检测到 SpektraLab 正在运行，请先关闭它。' -ForegroundColor Yellow
    exit 1
}

if (Test-Path $dst) {
    Write-Host '检测到已有安装，正在更新...' -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
}

# 复制程序文件（跳过安装脚本自身）
$skip = @('安装.cmd', '卸载.cmd', 'install.ps1', 'uninstall.ps1')
Get-ChildItem $src -Force | Where-Object { $skip -notcontains $_.Name } | ForEach-Object {
    Copy-Item $_.FullName $dst -Recurse -Force
}

# 快捷方式
$shell = New-Object -ComObject WScript.Shell
$targets = @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'SpektraLab.lnk'),
    (Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs\SpektraLab.lnk')
)
foreach ($lnk in $targets) {
    $shortcut = $shell.CreateShortcut($lnk)
    $shortcut.TargetPath = Join-Path $dst 'spektralab.exe'
    $shortcut.WorkingDirectory = $dst
    $shortcut.IconLocation = (Join-Path $dst 'spektralab.exe') + ',0'
    $shortcut.Description = 'SpektraLab — 胶片与相纸模拟'
    $shortcut.Save()
    Write-Host "  快捷方式: $lnk"
}

Write-Host ''
Write-Host '安装完成。桌面和开始菜单里都有 SpektraLab 了。' -ForegroundColor Green
Write-Host '首次启动如遇 SmartScreen 提示，点“更多信息”→“仍要运行”。'
Write-Host ''
Write-Host "卸载：运行安装目录下的 卸载.cmd，或删除 $dst"
