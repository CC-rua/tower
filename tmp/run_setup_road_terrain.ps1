$ErrorActionPreference = "Stop"

$godot = "C:\Users\cc\data\software\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
$project = "C:\Users\cc\data\godot\tower"
$script = "res://tmp/setup_road_terrain.gd"

if (-not (Test-Path $godot)) {
    throw "Godot executable not found: $godot"
}

$arguments = @("--headless", "--editor", "--quit-after", "1000", "--path", $project, "--script", $script)

Write-Host "Running: $godot $($arguments -join ' ')"
& $godot @arguments

if ($LASTEXITCODE -ne 0) {
    throw "Godot exited with code $LASTEXITCODE"
}
