-- Genera ventas históricas de demostración para recorrer analítica y predicción.
-- Los códigos VEC-HIST identifican estos registros como datos demo.
BEGIN;

CREATE TEMP TABLE vecor_history_payload ON COMMIT DROP AS
WITH dates AS (
  SELECT sale_day::date sale_day,row_number() OVER(ORDER BY sale_day)::int week_no
  FROM generate_series(date '2026-08-27',date '2026-11-19',interval '7 days') sale_day
)
SELECT 'VEC-HIST-'||to_char(d.sale_day,'YYMMDD') codigo,d.sale_day,d.week_no,
       s.sede_id,a.almacen_id,c.cliente_id,e.empleado_id,u.usuario_id,
       p.producto_id,p.sku,
       CASE p.sku WHEN 'CON-001' THEN 8+(d.week_no%5)
                  WHEN 'ELE-001' THEN 8+((d.week_no*3)%13)
                  WHEN 'PLO-001' THEN 6+((d.week_no*2)%8)
                  WHEN 'HER-001' THEN 2+(d.week_no%3)
                  ELSE 1+(d.week_no%3) END::numeric cantidad,
       pr.precio_venta::numeric precio_unitario,tx.porcentaje::numeric porcentaje,
       round((CASE p.sku WHEN 'CON-001' THEN 8+(d.week_no%5)
                         WHEN 'ELE-001' THEN 8+((d.week_no*3)%13)
                         WHEN 'PLO-001' THEN 6+((d.week_no*2)%8)
                         WHEN 'HER-001' THEN 2+(d.week_no%3)
                         ELSE 1+(d.week_no%3) END)*pr.precio_venta,2) subtotal,
       round((CASE p.sku WHEN 'CON-001' THEN 8+(d.week_no%5)
                         WHEN 'ELE-001' THEN 8+((d.week_no*3)%13)
                         WHEN 'PLO-001' THEN 6+((d.week_no*2)%8)
                         WHEN 'HER-001' THEN 2+(d.week_no%3)
                         ELSE 1+(d.week_no%3) END)*pr.precio_venta*tx.porcentaje/100,2) impuesto
FROM dates d
JOIN sedes s ON s.nombre=CASE WHEN d.week_no%2=1 THEN 'Casuarinas' ELSE 'San Luis' END
JOIN almacenes a ON a.sede_id=s.sede_id AND a.nombre='Almacén principal'
JOIN clientes c ON c.numero_documento=CASE WHEN d.week_no%2=1 THEN '70000001' ELSE '20600000001' END
JOIN empleados e ON e.documento='00000002'
JOIN usuarios u ON u.nombre_usuario='admin'
JOIN productos p ON p.sku IN('HER-001','CON-001','ELE-001','PLO-001','HER-002')
JOIN impuestos tx ON tx.impuesto_id=p.impuesto_id
JOIN LATERAL (SELECT pp.precio_venta FROM precios_producto pp WHERE pp.producto_id=p.producto_id ORDER BY (pp.fecha_inicio<=d.sale_day) DESC,pp.fecha_inicio DESC LIMIT 1) pr ON true;

INSERT INTO ventas(codigo_venta,sede_id,almacen_id,cliente_id,empleado_id,usuario_id,condicion_pago,fecha_venta,subtotal,impuesto_total,monto_total,estado)
SELECT codigo,sede_id,almacen_id,cliente_id,empleado_id,usuario_id,'CONTADO',sale_day::timestamp+time '10:00',sum(subtotal),sum(impuesto),sum(subtotal+impuesto),'COMPLETADA'
FROM vecor_history_payload
GROUP BY codigo,sale_day,sede_id,almacen_id,cliente_id,empleado_id,usuario_id
ON CONFLICT(codigo_venta) DO NOTHING;

INSERT INTO detalle_venta(venta_id,producto_id,cantidad,precio_unitario,descuento,impuesto,subtotal)
SELECT v.venta_id,h.producto_id,h.cantidad,h.precio_unitario,0,h.impuesto,h.subtotal
FROM vecor_history_payload h JOIN ventas v ON v.codigo_venta=h.codigo
WHERE NOT EXISTS(SELECT 1 FROM detalle_venta d WHERE d.venta_id=v.venta_id AND d.producto_id=h.producto_id);

INSERT INTO comprobantes(venta_id,tipo_comprobante_id,serie,numero,fecha_emision,estado)
SELECT v.venta_id,t.tipo_comprobante_id,'BH01',to_char(v.fecha_venta,'YYMMDD')||'01',v.fecha_venta,'EMITIDO'
FROM ventas v CROSS JOIN tipos_comprobante t
WHERE v.codigo_venta LIKE 'VEC-HIST-%' AND t.codigo='03'
ON CONFLICT DO NOTHING;

INSERT INTO pagos(venta_id,metodo_pago_id,monto,usuario_id,fecha_pago)
SELECT v.venta_id,m.metodo_pago_id,v.monto_total,v.usuario_id,v.fecha_venta
FROM ventas v CROSS JOIN metodos_pago m
WHERE v.codigo_venta LIKE 'VEC-HIST-%' AND m.nombre='Efectivo'
AND NOT EXISTS(SELECT 1 FROM pagos p WHERE p.venta_id=v.venta_id);

COMMIT;
