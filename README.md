
# Ferretería Vecor · Gestión comercial

Sistema comercial con frontend Angular, API REST Node.js/TypeScript y PostgreSQL. Catálogo compartido y existencias siempre separadas por almacén/sede.

## Requisitos

- Node.js 20+
- Docker Desktop (o PostgreSQL 16 local)

## Inicio local

1. Copia `.env.example` a `backend/.env` y configura `JWT_SECRET` para tu entorno.
2. Inicia PostgreSQL y carga el esquema y datos ficticios: `docker compose up -d db`.
3. Instala dependencias: `npm --prefix backend install` y `npm --prefix frontend install`.
4. Inicia API: `npm run dev:api`; inicia frontend en otra terminal: `npm --prefix frontend start`.
5. Abre `http://localhost:4200`.

Usuario inicial: `admin` · Contraseña: `Vecor2026!`. Cambia la contraseña y secreto antes de cualquier despliegue.

## Ejecutar en otra PC con Docker

La aplicación se distribuye como tres servicios Docker: interfaz web, API y PostgreSQL. En la PC de destino instala Docker Desktop y espera a que indique **Engine running**. Copia la carpeta del proyecto (o un ZIP) incluyendo `docker-compose.yml`, `backend/`, `frontend/` y `database/`; no copies `.env`, `node_modules`, `dist` ni `.git`.

En PowerShell, desde la carpeta del proyecto:

```powershell
Copy-Item .env.example .env
notepad .env
```

En `.env`, cambia `JWT_SECRET` y `POSTGRES_PASSWORD` por valores propios. Luego construye y arranca todo:

```powershell
docker compose up --build -d
docker compose ps
```

Abre `http://localhost:8080`. La cuenta inicial es `admin` · `Vecor2026!`; cambia esa contraseña antes de usar información real. PostgreSQL se inicializa automáticamente con el esquema, migración analítica y datos demostrativos, solo la primera vez que se crea el volumen.

Para abrir la aplicación desde otra computadora de la misma red, permite el puerto TCP `8080` en el firewall de Windows de la PC anfitriona y entra desde el navegador a `http://IP-DE-LA-PC:8080`. La base de datos permanece en el volumen Docker de la PC anfitriona; no se duplica ni sincroniza al copiar la carpeta. Para trasladar también las ventas reales, genera un respaldo en la PC de origen y restáuralo en destino:

```powershell
docker compose exec -T db pg_dump -U vecor -d vecor -Fc -f /tmp/vecor.backup
docker compose cp db:/tmp/vecor.backup ./vecor.backup
# Copia vecor.backup a la PC de destino y primero inicia allí los contenedores.
docker compose cp ./vecor.backup db:/tmp/vecor.backup
docker compose exec -T db pg_restore -U vecor -d vecor --clean --if-exists /tmp/vecor.backup
```

Comandos prácticos:

```powershell
docker compose logs -f
docker compose down       # detiene los servicios y conserva la base de datos
docker compose down -v    # elimina también la base de datos; no usar si quieres conservarla
```

## Reglas de inventario

Cada inventario y movimiento apunta a un almacén. El almacén pertenece a una sede; ventas y compras validan en una transacción que la sede seleccionada coincida con la sede del almacén. La venta bloquea las filas afectadas y rechaza existencias insuficientes. Una sede no puede alterar stock de la otra.

El informe académico adjunto sirvió como referencia para las entidades, relaciones y reglas. Sus descripciones del sistema vigente son tratadas como contexto no confirmado.

## Analítica y predicción

El módulo **Analítica y Predicción** consulta ventas y detalles originales, segmentados por sede, producto, variante, categoría, marca y vendedor. Las existencias, cobertura y recomendaciones se calculan por separado para cada sede incluso cuando se seleccionan todas. Incluye rankings por unidades, ingresos y frecuencia; tendencia frente al período anterior; productos sin movimiento; cobertura y comparación de sedes.

Las estimaciones usan un promedio móvil ponderado (últimos 30 días al 65%, 30 días previos al 35%) y solo se ofrecen con al menos 60 días de historial y cinco fechas con ventas. Una estimación es orientativa. Al generarla, el sistema la guarda en `analytics_predictions`; al cerrarse el período futuro, coteja la venta registrada y calcula MAE, RMSE y MAPE. La precisión se muestra a partir de cinco períodos cerrados. Los datos originales de ventas no se editan.

Exporta la vista filtrada a CSV, XLSX y PDF desde el módulo. Para una base de datos ya inicializada antes del módulo, aplica la migración:

```powershell
Get-Content database/migrations/002_analytics.sql | docker exec -i vecor-postgres psql -U vecor -d vecor
```
