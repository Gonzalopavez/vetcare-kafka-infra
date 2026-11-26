# VetCare EV3 - Infraestructura local Apache Kafka

Esta carpeta ofrece **dos arquitecturas independientes** para la demostracion de la EV3:

- `docker-compose.yml`: **ZooKeeper + 3 brokers Kafka + Kafka UI**, arquitectura solicitada en la rubrica. Es una configuracion nueva por probar en el computador de los integrantes.
- `referencias/docker-compose.kraft.yml`: copia del Compose del cluster KRaft de 3 brokers que el equipo ya probo previamente. **Solo de referencia: no ejecutarlo desde esta carpeta**, porque la instancia original tiene datos, volumenes y su propio `.env` en `~/vetcare-kafka-cluster`.

## Puertos de la nueva configuracion ZooKeeper

| Servicio | Puerto Windows | Destino |
| --- | --- | --- |
| Kafka broker 1 | `localhost:29092` | Aplicaciones Java locales |
| Kafka broker 2 | `localhost:29093` | Aplicaciones Java locales |
| Kafka broker 3 | `localhost:29094` | Aplicaciones Java locales |
| Kafka UI | `http://127.0.0.1:8091` | Interfaz web local |
| ZooKeeper | Solo interno | Los brokers lo consultan por `zookeeper:2181` |

Todas las exposiciones al host estan limitadas a `127.0.0.1`. ZooKeeper y Kafka UI no tienen autenticacion: **esta configuracion no debe exponerse a internet ni utilizarse tal cual en AWS**.

## Levantar ZooKeeper + 3 brokers + UI

Desde PowerShell en esta carpeta:

```powershell
docker compose config --quiet
docker compose up -d
docker compose ps
```

Es preferible **detener** el cluster KRaft original antes de levantar esta alternativa, si Docker Desktop dispone de poca memoria. No eliminar volumenes ni usar `down -v` en ninguno de los dos clusters.

Cuando los tres brokers esten listos, crear los topicos del proyecto:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\crear-topicos.ps1
```

Topicos: `consultations.events`, `audit.timeline`, `consultations.events.audit.DLT`. El script crea topicos solo si faltan, con 3 particiones, replicacion 3, `min.insync.replicas=2`, retencion y politicas de limpieza explicitas. No modifica la configuracion de topicos ya existentes.

Consultar estado:

```powershell
docker compose ps
docker compose exec -T kafka-1 kafka-topics --bootstrap-server kafka-1:9092 --describe --topic consultations.events
```

La Kafka UI estara en `http://127.0.0.1:8091`.

Para conectar las aplicaciones **desde Windows** al cluster ZooKeeper se necesita `KAFKA_BOOTSTRAP_SERVERS=localhost:29092,localhost:29093,localhost:29094`. Para conectar aplicaciones que se ejecutan **dentro de la misma red de Docker Compose**, usar `kafka-1:9092,kafka-2:9092,kafka-3:9092`.

Para detener la configuracion ZooKeeper conservando los datos:

```powershell
docker compose stop
```

## Notas y limites

- Solo hay **un nodo ZooKeeper**. La replicacion de Kafka es de 3 brokers, pero **ZooKeeper no es tolerante a fallos** en esta configuracion local.
- La persistencia utiliza volumenes Docker separados de los usados por el cluster KRaft original.
- No se configura autenticacion SASL/TLS ni autorizacion ACL: se trata de una demo local.
- Los brokers y la UI se han preparado para el sistema local, **no se ha validado su arranque** en el computador del equipo hasta ejecutar los comandos anteriores.
- El cluster local ZooKeeper y la evidencia de Docker Compose **no sustituyen** desplegar o comprobar una arquitectura multi-nodo en AWS, si la rubrica la exige.
