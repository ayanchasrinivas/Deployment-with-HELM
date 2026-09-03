CREATE TABLE IF NOT EXISTS sku_overrides (
    sku        TEXT PRIMARY KEY,
    multiplier NUMERIC(6,3) NOT NULL DEFAULT 1.000,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);