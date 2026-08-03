$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$temp = Join-Path $root '.android_core_download'
New-Item -ItemType Directory -Force -Path $temp | Out-Null

$targets = @(
    @{ Abi = 'arm64-v8a'; Core = 'SameBoy'; Package = 'sameboy_libretro_android.so.zip'; Output = 'libsameboy_libretro.so' },
    @{ Abi = 'arm64-v8a'; Core = 'mGBA'; Package = 'mgba_libretro_android.so.zip'; Output = 'libmgba_libretro.so' },
    @{ Abi = 'x86_64'; Core = 'SameBoy'; Package = 'sameboy_libretro_android.so.zip'; Output = 'libsameboy_libretro.so' },
    @{ Abi = 'x86_64'; Core = 'mGBA'; Package = 'mgba_libretro_android.so.zip'; Output = 'libmgba_libretro.so' }
)

try {
    foreach ($target in $targets) {
        $abi = $target.Abi
        $coreName = $target.Core
        $zip = Join-Path $temp "$($target.Output)-$abi.zip"
        $extract = Join-Path $temp "$($target.Output)-$abi"
        $destination = Join-Path $root "android/app/src/main/jniLibs/$abi"
        $url = "https://buildbot.libretro.com/nightly/android/latest/$abi/$($target.Package)"

        Write-Host "Descargando $coreName para $abi..."
        Invoke-WebRequest -Uri $url -OutFile $zip
        Remove-Item -Recurse -Force $extract -ErrorAction SilentlyContinue
        Expand-Archive -Path $zip -DestinationPath $extract -Force
        New-Item -ItemType Directory -Force -Path $destination | Out-Null

        $core = Get-ChildItem -Path $extract -Recurse -Filter '*.so' | Select-Object -First 1
        if ($null -eq $core) {
            throw "El paquete de $coreName para $abi no contiene una biblioteca .so."
        }

        Copy-Item $core.FullName (Join-Path $destination $target.Output) -Force
    }
}
finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
}

Write-Host 'SameBoy y mGBA para Android preparados correctamente.'
