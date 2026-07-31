$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$temp = Join-Path $root '.android_core_download'
New-Item -ItemType Directory -Force -Path $temp | Out-Null

$targets = @(
    @{
        Abi = 'arm64-v8a'
        Url = 'https://buildbot.libretro.com/nightly/android/latest/arm64-v8a/sameboy_libretro_android.so.zip'
    },
    @{
        Abi = 'x86_64'
        Url = 'https://buildbot.libretro.com/nightly/android/latest/x86_64/sameboy_libretro_android.so.zip'
    }
)

foreach ($target in $targets) {
    $abi = $target.Abi
    $zip = Join-Path $temp "sameboy-$abi.zip"
    $extract = Join-Path $temp $abi
    $destination = Join-Path $root "android/app/src/main/jniLibs/$abi"

    Write-Host "Descargando SameBoy para $abi..."
    Invoke-WebRequest -Uri $target.Url -OutFile $zip
    Remove-Item -Recurse -Force $extract -ErrorAction SilentlyContinue
    Expand-Archive -Path $zip -DestinationPath $extract -Force
    New-Item -ItemType Directory -Force -Path $destination | Out-Null

    $core = Get-ChildItem -Path $extract -Recurse -Filter '*.so' | Select-Object -First 1
    if ($null -eq $core) {
        throw "El ZIP de $abi no contiene una biblioteca .so."
    }

    Copy-Item $core.FullName (Join-Path $destination 'libsameboy_libretro.so') -Force
}

Remove-Item -Recurse -Force $temp
Write-Host 'SameBoy Android preparado correctamente.'
