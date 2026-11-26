# Inicializa los tres topicos de VetCare en el cluster local con ZooKeeper.
# Requiere Docker Compose en ejecucion y los tres brokers listos.
$ErrorActionPreference = "Stop"
$raiz = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $raiz
try {
    $topicos = @(
        @{ Nombre = "consultations.events"; Politica = "delete"; Retencion = "604800000" },
        @{ Nombre = "audit.timeline"; Politica = "compact,delete"; Retencion = "604800000" },
        @{ Nombre = "consultations.events.audit.DLT"; Politica = "delete"; Retencion = "1209600000" }
    )

    foreach ($topico in $topicos) {
        Write-Host "Creando/verificando $($topico.Nombre)..."
        & docker compose exec -T kafka-1 kafka-topics `
            --bootstrap-server kafka-1:9092 `
            --create --if-not-exists `
            --topic $topico.Nombre `
            --partitions 3 --replication-factor 3 `
            --config "min.insync.replicas=2" `
            --config "cleanup.policy=$($topico.Politica)" `
            --config "retention.ms=$($topico.Retencion)"

        if ($LASTEXITCODE -ne 0) {
            throw "No se pudo crear/verificar el topico $($topico.Nombre). Comprueba que los 3 brokers esten listos."
        }
    }

    Write-Host "Topicos del cluster:"
    & docker compose exec -T kafka-1 kafka-topics --bootstrap-server kafka-1:9092 --list
    if ($LASTEXITCODE -ne 0) { throw "Fallo la consulta de topicos." }

    Write-Host "Configuracion inicial completada."
} finally {
    Pop-Location
}
