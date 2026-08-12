# KIMUN - Respaldo automatico diario (18:00)
# Hace commit y push SOLO si hay cambios sin guardar en el repositorio.
# Se registra como Tarea Programada de Windows (ver scripts/registrar-tarea.ps1).

$ErrorActionPreference = 'Stop'
$repo = 'C:\Proyectos\kimun'
$log  = Join-Path $repo 'scripts\auto-commit.log'

function Escribir-Log($mensaje) {
    $marca = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "[$marca] $mensaje" -Encoding utf8
}

try {
    Set-Location $repo

    # Verificar si hay cambios (avances del dia)
    $cambios = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($cambios)) {
        Escribir-Log 'Sin cambios. No se hace nada.'
        exit 0
    }

    $rama  = (git rev-parse --abbrev-ref HEAD).Trim()
    $fecha = Get-Date -Format 'yyyy-MM-dd'

    git add -A
    $mensaje = @"
Auto-commit diario (18:00): avances del $fecha

Respaldo automatico de KIMUN. Contiene los cambios del dia que aun
no se habian confirmado manualmente.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
"@
    git commit -m $mensaje | Out-Null
    git push origin $rama | Out-Null

    Escribir-Log "Commit y push OK en rama '$rama'."
    exit 0
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
