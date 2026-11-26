CREATE TABLE IF NOT EXISTS analytics_predictions(
  prediction_id BIGSERIAL PRIMARY KEY,
  producto_id BIGINT NOT NULL REFERENCES productos,
  variante_id BIGINT REFERENCES variantes_producto,
  sede_id BIGINT REFERENCES sedes,
  periodo_inicio DATE NOT NULL,
  periodo_fin DATE NOT NULL,
  demanda_estimada NUMERIC(14,3) NOT NULL CHECK(demanda_estimada>=0),
  metodo VARCHAR(40) NOT NULL,
  datos_base JSONB NOT NULL DEFAULT '{}',
  generado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK(periodo_fin>=periodo_inicio)
);
CREATE INDEX IF NOT EXISTS idx_predictions_product_period
  ON analytics_predictions(producto_id,variante_id,sede_id,periodo_inicio DESC);
