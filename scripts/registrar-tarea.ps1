# KIMUN - Registra la tarea programada de respaldo automatico (18:00 diario).
# Ejecutar UNA VEZ en cada PC (oficina y casa) donde trabajes el proyecto.
# Uso:  powershell -ExecutionPolicy Bypass -File scripts\registrar-tarea.ps1

$scriptPath = Join-Path $PSScriptRoot 'auto-commit.ps1'
$accion = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

schtasks /Create /TN "KIMUN auto-commit 18h" /TR $accion /SC DAILY /ST 18:00 /F

Write-Host ""
Write-Host "Tarea 'KIMUN auto-commit 18h' registrada. Correra todos los dias a las 18:00."
Write-Host "Solo hara commit y push si ese dia hay cambios sin guardar."
