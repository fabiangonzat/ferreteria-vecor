-- Datos demostrativos complementarios para las tablas transaccionales.
-- Se puede ejecutar varias veces sin duplicar las filas identificadas.
BEGIN;

INSERT INTO variantes_producto(producto_id,sku,nombre,atributos)
SELECT p.producto_id,'HER-001-DEMO-V1','Mango de fibra (demo)','{"material":"fibra","demo":true}'::jsonb
FROM productos p WHERE p.sku='HER-001'
ON CONFLICT DO NOTHING;

INSERT INTO producto_unidad(producto_id,unidad_id,factor_conversion)
SELECT p.producto_id,u.unidad_id,6
FROM productos p CROSS JOIN unidades_medida u
WHERE p.sku='HER-001' AND u.sigla='cj'
ON CONFLICT DO NOTHING;

INSERT INTO cajas(sede_id,nombre)
SELECT s.sede_id,'Caja principal (demo)' FROM sedes s WHERE s.nombre='Casuarinas' AND NOT EXISTS(SELECT 1 FROM cajas c WHERE c.sede_id=s.sede_id AND c.nombre='Caja principal (demo)')
ON CONFLICT DO NOTHING;

INSERT INTO caja_sesiones(caja_id,usuario_apertura,usuario_cierre,monto_inicial,monto_final,diferencia,abierta_en,cerrada_en,estado)
SELECT c.caja_id,u.usuario_id,u.usuario_id,200,583.50,383.50,'2026-11-10 08:00:00-05','2026-11-10 18:00:00-05','CERRADA'
FROM cajas c CROSS JOIN usuarios u
WHERE c.nombre='Caja principal (demo)' AND c.estado=true AND u.nombre_usuario='admin'
AND NOT EXISTS(SELECT 1 FROM caja_sesiones x WHERE x.caja_id=c.caja_id AND x.abierta_en='2026-11-10 08:00:00-05');

INSERT INTO ventas(codigo_venta,sede_id,almacen_id,cliente_id,empleado_id,usuario_id,condicion_pago,fecha_venta,subtotal,impuesto_total,monto_total,estado)
SELECT 'VEC-DEMO-2026-001',s.sede_id,a.almacen_id,c.cliente_id,e.empleado_id,u.usuario_id,'CONTADO','2026-11-10 10:15:00-05',325,58.50,383.50,'COMPLETADA'
FROM sedes s JOIN almacenes a USING(sede_id) CROSS JOIN clientes c CROSS JOIN empleados e CROSS JOIN usuarios u
WHERE s.nombre='Casuarinas' AND a.nombre='Almacén principal' AND c.numero_documento='70000001' AND e.documento='00000001' AND u.nombre_usuario='admin'
ON CONFLICT(codigo_venta) DO NOTHING;

INSERT INTO detalle_venta(venta_id,producto_id,cantidad,precio_unitario,descuento,impuesto,subtotal)
SELECT v.venta_id,p.producto_id,10,32.50,0,58.50,325
FROM ventas v CROSS JOIN productos p WHERE v.codigo_venta='VEC-DEMO-2026-001' AND p.sku='CON-001'
AND NOT EXISTS(SELECT 1 FROM detalle_venta d WHERE d.venta_id=v.venta_id);

INSERT INTO comprobantes(venta_id,tipo_comprobante_id,serie,numero,fecha_emision,estado)
SELECT v.venta_id,t.tipo_comprobante_id,'B001','00000001','2026-11-10 10:15:00-05','EMITIDO'
FROM ventas v CROSS JOIN tipos_comprobante t WHERE v.codigo_venta='VEC-DEMO-2026-001' AND t.codigo='03'
ON CONFLICT DO NOTHING;

INSERT INTO pagos(venta_id,metodo_pago_id,monto,usuario_id,fecha_pago)
SELECT v.venta_id,m.metodo_pago_id,383.50,u.usuario_id,'2026-11-10 10:16:00-05'
FROM ventas v CROSS JOIN metodos_pago m CROSS JOIN usuarios u WHERE v.codigo_venta='VEC-DEMO-2026-001' AND m.nombre='Efectivo' AND u.nombre_usuario='admin'
AND NOT EXISTS(SELECT 1 FROM pagos p WHERE p.venta_id=v.venta_id);

INSERT INTO ventas(codigo_venta,sede_id,almacen_id,cliente_id,empleado_id,usuario_id,condicion_pago,fecha_venta,subtotal,impuesto_total,monto_total,estado)
SELECT 'VEC-DEMO-2026-002',s.sede_id,a.almacen_id,c.cliente_id,e.empleado_id,u.usuario_id,'CREDITO','2026-11-18 14:30:00-05',812.50,146.25,958.75,'COMPLETADA'
FROM sedes s JOIN almacenes a USING(sede_id) CROSS JOIN clientes c CROSS JOIN empleados e CROSS JOIN usuarios u
WHERE s.nombre='Casuarinas' AND a.nombre='Almacén principal' AND c.numero_documento='20600000001' AND e.documento='00000002' AND u.nombre_usuario='admin'
ON CONFLICT(codigo_venta) DO NOTHING;

INSERT INTO detalle_venta(venta_id,producto_id,cantidad,precio_unitario,descuento,impuesto,subtotal)
SELECT v.venta_id,p.producto_id,25,32.50,0,146.25,812.50
FROM ventas v CROSS JOIN productos p WHERE v.codigo_venta='VEC-DEMO-2026-002' AND p.sku='CON-001'
AND NOT EXISTS(SELECT 1 FROM detalle_venta d WHERE d.venta_id=v.venta_id);

INSERT INTO cuentas_por_cobrar(venta_id,monto_total,saldo_pendiente,fecha_emision,fecha_vencimiento,estado)
SELECT v.venta_id,958.75,658.75,'2026-11-18','2026-12-18','PARCIAL'
FROM ventas v WHERE v.codigo_venta='VEC-DEMO-2026-002'
ON CONFLICT(venta_id) DO NOTHING;

INSERT INTO pagos_cuenta_cobrar(cuenta_id,metodo_pago_id,monto,usuario_id,fecha_pago)
SELECT cc.cuenta_id,m.metodo_pago_id,300,u.usuario_id,'2026-11-20 12:00:00-05'
FROM cuentas_por_cobrar cc JOIN ventas v USING(venta_id) CROSS JOIN metodos_pago m CROSS JOIN usuarios u
WHERE v.codigo_venta='VEC-DEMO-2026-002' AND m.nombre='Transferencia' AND u.nombre_usuario='admin'
AND NOT EXISTS(SELECT 1 FROM pagos_cuenta_cobrar p WHERE p.cuenta_id=cc.cuenta_id);

INSERT INTO comprobantes(venta_id,tipo_comprobante_id,serie,numero,fecha_emision,estado)
SELECT v.venta_id,t.tipo_comprobante_id,'F001','00000001','2026-11-18 14:30:00-05','EMITIDO'
FROM ventas v CROSS JOIN tipos_comprobante t WHERE v.codigo_venta='VEC-DEMO-2026-002' AND t.codigo='01'
ON CONFLICT DO NOTHING;

INSERT INTO compras(codigo_compra,proveedor_id,sede_id,almacen_id,usuario_id,fecha_compra,subtotal,impuesto_total,flete,monto_total,condicion_pago,estado)
SELECT 'COM-DEMO-2026-001',pr.proveedor_id,s.sede_id,a.almacen_id,u.usuario_id,'2026-11-05 09:00:00-05',2400,432,100,2932,'CONTADO','RECIBIDA'
FROM proveedores pr CROSS JOIN sedes s JOIN almacenes a USING(sede_id) CROSS JOIN usuarios u
WHERE pr.numero_documento='20100000001' AND s.nombre='Casuarinas' AND a.nombre='Almacén principal' AND u.nombre_usuario='admin'
ON CONFLICT(codigo_compra) DO NOTHING;

INSERT INTO detalle_compra(compra_id,producto_id,cantidad,costo_unitario,impuesto,subtotal)
SELECT co.compra_id,p.producto_id,100,24,432,2400
FROM compras co CROSS JOIN productos p WHERE co.codigo_compra='COM-DEMO-2026-001' AND p.sku='CON-001'
AND NOT EXISTS(SELECT 1 FROM detalle_compra d WHERE d.compra_id=co.compra_id);

INSERT INTO movimientos_inventario(producto_id,almacen_id,usuario_id,tipo_movimiento,cantidad,costo_unitario,fecha_movimiento,referencia,observacion)
SELECT p.producto_id,a.almacen_id,u.usuario_id,'COMPRA',100,24,'2026-11-05 09:05:00-05','COM-DEMO-2026-001','Recepción demostrativa de cemento'
FROM productos p CROSS JOIN almacenes a JOIN sedes s USING(sede_id) CROSS JOIN usuarios u WHERE p.sku='CON-001' AND a.nombre='Almacén principal' AND s.nombre='Casuarinas' AND u.nombre_usuario='admin'
AND NOT EXISTS(SELECT 1 FROM movimientos_inventario m WHERE m.referencia='COM-DEMO-2026-001');

INSERT INTO movimientos_inventario(producto_id,almacen_id,usuario_id,tipo_movimiento,cantidad,costo_unitario,fecha_movimiento,referencia,observacion)
SELECT p.producto_id,a.almacen_id,u.usuario_id,'VENTA',10,32.50,'2026-11-10 10:15:00-05','VEC-DEMO-2026-001','Salida por venta demostrativa'
FROM productos p CROSS JOIN almacenes a JOIN sedes s USING(sede_id) CROSS JOIN usuarios u WHERE p.sku='CON-001' AND a.nombre='Almacén principal' AND s.nombre='Casuarinas' AND u.nombre_usuario='admin'
AND NOT EXISTS(SELECT 1 FROM movimientos_inventario m WHERE m.referencia='VEC-DEMO-2026-001');

INSERT INTO devoluciones(tipo,venta_id,cliente_id,empleado_id,usuario_id,motivo_id,fecha,motivo,monto)
SELECT 'VENTA',v.venta_id,v.cliente_id,v.empleado_id,v.usuario_id,m.motivo_id,'2026-11-12 11:00:00-05','Devolución demostrativa de una bolsa dañada',38.35
FROM ventas v CROSS JOIN motivos_devolucion m WHERE v.codigo_venta='VEC-DEMO-2026-001' AND m.nombre='Producto defectuoso'
AND NOT EXISTS(SELECT 1 FROM devoluciones d WHERE d.venta_id=v.venta_id AND d.motivo='Devolución demostrativa de una bolsa dañada');

INSERT INTO detalle_devoluciones(devolucion_id,producto_id,almacen_id,cantidad,monto)
SELECT d.devolucion_id,p.producto_id,a.almacen_id,1,38.35
FROM devoluciones d CROSS JOIN productos p CROSS JOIN almacenes a JOIN sedes s USING(sede_id)
WHERE d.motivo='Devolución demostrativa de una bolsa dañada' AND p.sku='CON-001' AND a.nombre='Almacén principal' AND s.nombre='Casuarinas'
AND NOT EXISTS(SELECT 1 FROM detalle_devoluciones x WHERE x.devolucion_id=d.devolucion_id);

INSERT INTO notas_credito(venta_id,comprobante_id,motivo,monto,fecha_emision)
SELECT v.venta_id,c.comprobante_id,'Nota de crédito demostrativa por devolución parcial',38.35,'2026-11-12 11:05:00-05'
FROM ventas v JOIN comprobantes c USING(venta_id) WHERE v.codigo_venta='VEC-DEMO-2026-001'
AND NOT EXISTS(SELECT 1 FROM notas_credito n WHERE n.venta_id=v.venta_id AND n.motivo='Nota de crédito demostrativa por devolución parcial');

INSERT INTO analytics_predictions(producto_id,sede_id,periodo_inicio,periodo_fin,demanda_estimada,metodo,datos_base,generado_en)
SELECT p.producto_id,s.sede_id,'2026-12-01','2026-12-31',42,'Ejemplo demostrativo','{"periodo":"noviembre 2026","demo":true}'::jsonb,'2026-11-26 08:00:00-05'
FROM productos p CROSS JOIN sedes s WHERE p.sku='CON-001' AND s.nombre='Casuarinas'
AND NOT EXISTS(SELECT 1 FROM analytics_predictions ap WHERE ap.producto_id=p.producto_id AND ap.sede_id=s.sede_id AND ap.periodo_inicio='2026-12-01' AND ap.metodo='Ejemplo demostrativo');

INSERT INTO logs_auditoria(usuario_id,accion,tabla_afectada,registro_id,valores_nuevos,ip,fecha_hora)
SELECT u.usuario_id,'CARGAR_DATOS_DEMO','ventas',v.venta_id,'{"origen":"database/seed_demo.sql","demo":true}'::jsonb,'127.0.0.1','2026-11-26 08:00:00-05'
FROM usuarios u JOIN ventas v ON v.codigo_venta='VEC-DEMO-2026-001'
WHERE u.nombre_usuario='admin' AND NOT EXISTS(SELECT 1 FROM logs_auditoria l WHERE l.accion='CARGAR_DATOS_DEMO' AND l.tabla_afectada='ventas' AND l.registro_id=v.venta_id);

COMMIT;
