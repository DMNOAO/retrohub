$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$temp = Join-Path $root '.windows_core_download'
$destination = Join-Path $root 'cores/mgba'
$zip = Join-Path $temp 'mgba_libretro.dll.zip'
$url = 'https://buildbot.libretro.com/nightly/windows/x86_64/latest/mgba_libretro.dll.zip'

New-Item -ItemType Directory -Force -Path $temp | Out-Null

try {
    Write-Host 'Descargando mGBA para Windows x64...'
    Invoke-WebRequest -Uri $url -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $temp -Force
    New-Item -ItemType Directory -Force -Path $destination | Out-Null

    $core = Get-ChildItem -Path $temp -Recurse -Filter 'mgba_libretro.dll' | Select-Object -First 1
    if ($null -eq $core) {
        throw 'El paquete de mGBA no contiene mgba_libretro.dll.'
    }

    Copy-Item $core.FullName (Join-Path $destination 'mgba_libretro.dll') -Force
}
finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
}

Write-Host 'mGBA para Windows preparado correctamente.'
