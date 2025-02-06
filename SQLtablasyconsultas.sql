CREATE TABLE cryptocurrencies (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50),
    symbol VARCHAR(10),
    name VARCHAR(100),
    current_price NUMERIC,
    market_cap NUMERIC,
    total_volume NUMERIC,
    last_updated TIMESTAMP
);
CREATE TABLE historical_prices (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) NOT NULL,
    price NUMERIC(18, 2) NOT NULL,
    market_cap NUMERIC(18, 2) NOT NULL,
    total_volume NUMERIC(18, 2) NOT NULL,
    timestamp TIMESTAMP NOT NULL
);

--indices para las consultas mas frecuentes
CREATE INDEX idx_coin_id ON historical_prices (coin_id);
CREATE INDEX idx_timestamp ON historical_prices (timestamp);

-- vistas para reportes

--top 10 crypto
CREATE VIEW top_10_cryptos_by_market_cap AS
SELECT name, symbol, market_cap
FROM cryptocurrencies
ORDER BY market_cap DESC
LIMIT 10;
--precio historico de bitcoin
CREATE VIEW bitcoin_price_history AS
SELECT timestamp, price
FROM historical_prices
WHERE coin_id = 'bitcoin'
ORDER BY timestamp;
--volumen de operaciones ultima semana 
CREATE VIEW total_volume_last_7_days AS
SELECT coin_id, SUM(total_volume) AS total_volume_7d
FROM historical_prices
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY coin_id;

--Consultas para los reportes creados ejemplos
SELECT * FROM top_10_cryptos_by_market_cap;
SELECT * FROM bitcoin_price_history;
SELECT * FROM total_volume_last_7_days;
SELECT coin_id, 
       (MAX(price) - MIN(price)) / MIN(price) * 100 AS growth_percentage
FROM historical_prices
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY coin_id
ORDER BY growth_percentage DESC;