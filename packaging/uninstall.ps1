# SpektraLab 卸载脚本：删除安装目录与快捷方式
$ErrorActionPreference = 'SilentlyContinue'

$dst = Join-Path $env:LOCALAPPDATA 'SpektraLab'

Write-Host 'SpektraLab 卸载程序' -ForegroundColor Cyan
Write-Host "  安装目录: $dst"

if (Get-Process spektralab -ErrorAction SilentlyContinue) {
    Write-Host '请先关闭 SpektraLab 再卸载。' -ForegroundColor Yellow
    exit 1
}

$answer = Read-Host '确认卸载？(y/N)'
if ($answer -ne 'y' -and $answer -ne 'Y') { Write-Host '已取消。'; exit 0 }

foreach ($lnk in @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'SpektraLab.lnk'),
    (Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs\SpektraLab.lnk'))) {
    if (Test-Path $lnk) { Remove-Item $lnk -Force; Write-Host "  已删除 $lnk" }
}

if (Test-Path $dst) {
    Remove-Item $dst -Recurse -Force
    Write-Host '  已删除程序目录（照片与胶片设置保存在 %APPDATA%\app.spektralab.desktop，未删除）'
}

Write-Host '卸载完成。' -ForegroundColor Green
