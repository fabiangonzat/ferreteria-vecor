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
