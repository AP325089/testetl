# Proyecto ETL con CoinGecko

Este proyecto implementa un flujo ETL (Extract, Transform, Load) para obtener datos de criptomonedas desde la API de CoinGecko, transformarlos y cargarlos en una base de datos PostgreSQL.

Herramientas Elegidas y Justificación
	1	Python:
	◦	Lenguaje de programación versátil y ampliamente utilizado para ETL.
	◦	Bibliotecas como requests (para llamadas API), pandas (para manipulación de datos) y sqlalchemy (para conexión a bases de datos) son     
  ideales para este proyecto.
	2	PostgreSQL:
	◦	Base de datos relacional robusta y de código abierto.
	◦	Ideal para almacenar datos estructurados y realizar consultas complejas.
	3	GitHub: 
	◦	Plataforma para alojar el código y la documentación del proyecto.
	◦	Facilita la colaboración y el control de versiones.
	4	Postman:
	◦	Herramienta para probar y validar las respuestas de la API antes de implementar el código en Python.
	5	Diagramas ER:
	◦	app.diagrams para diseñar el modelo de datos.(es gratuito)


Requisitos
- Python 3.8 o superior.
- PostgreSQL instalado y configurado.

Dependencias
- Se dejo un archivo para la instalación de los requerimientos llamado: requeriments.txt

- Revisión de API pública

Antes de comenzar con la configuración se observaron en Postman  las API para probar endpoints.

Configura la base de datos:

Crea una base de datos en PostgreSQL llamada coingecko, dentro de la base ejecutamos el siguiente SQL para crear las tablas que necesitarmos:

CREATE TABLE cryptocurrencies (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    current_price NUMERIC(18, 2) NOT NULL,
    market_cap NUMERIC(18, 2) NOT NULL,
    total_volume NUMERIC(18, 2) NOT NULL,
    last_updated TIMESTAMP NOT NULL
);

CREATE TABLE historical_prices (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) NOT NULL,
    price NUMERIC(18, 2) NOT NULL,
    market_cap NUMERIC(18, 2) NOT NULL,
    total_volume NUMERIC(18, 2) NOT NULL,
    timestamp TIMESTAMP NOT NULL
);


Una vez creadas las tablas en mi caso utilice el IDE PyCharm para programar en python dejo el codigo utlizado y una explicación de su funcionamiento , adjunto el codigo para su uso en el repositorio:

import requests
import pandas as pd
from sqlalchemy import create_engine

# Configurar la conexión a PostgreSQL
engine = create_engine('postgresql://postgres:Ramon1998@localhost:5432/coingecko')

# Lista de criptomonedas a monitorear
cryptos = ['bitcoin', 'ethereum', 'ripple']

# Extraer, transformar y cargar datos históricos
for crypto in cryptos:
    url = f"https://api.coingecko.com/api/v3/coins/{crypto}/market_chart"
    params = {
        "vs_currency": "usd",
        "days": "30"
    }
    response = requests.get(url, params=params)
    data = response.json()

# Transformar los datos
  prices = data.get('prices', [])
  market_caps = data.get('market_caps', [])
  total_volumes = data.get('total_volumes', [])

   historical_data = []
    for i in range(len(prices)):
        timestamp = pd.to_datetime(prices[i][0], unit='ms')
        price = prices[i][1]
        market_cap = market_caps[i][1]
        total_volume = total_volumes[i][1]
        historical_data.append([timestamp, price, market_cap, total_volume])

  df_historical = pd.DataFrame(historical_data, columns=['timestamp', 'price', 'market_cap', 'total_volume'])
  df_historical['coin_id'] = crypto

  # Cargar los datos en PostgreSQL
  df_historical.to_sql('historical_prices', engine, if_exists='append', index=False)
  print(f"Datos históricos de {crypto} cargados correctamente.")

Extracción:
Llamada a la API: Usamos requests.get() para obtener los datos de CoinGecko.
Verificación de la respuesta: Comprobamos que la respuesta tenga un código de estado 200 (éxito). Si no es así, mostramos un mensaje de error.
Creación del DataFrame: Solo si data está definido y contiene datos, procedemos a crear el DataFrame con pd.DataFrame(data).

Transformación:
Se crea un DataFrame con las columnas relevantes y se convierte la columna last_updated a formato datetime.
Limpieza de Datos:
Eliminar campos innecesarios.
Manejar valores nulos o inconsistentes.
Convertir tipos de datos (por ejemplo, fechas a formato datetime).
Estructuración:
Crear un DataFrame con pandas para facilitar la manipulación.


Carga:
Usar sqlalchemy para cargar el DataFrame en la base de datos.
Se establece una conexión a PostgreSQL usando sqlalchemy.
Se carga el DataFrame en la tabla cryptocurrencies usando el método to_sql.




Para diseñar el Modelo de Datos para Reporteo se optimizaron las tablas que fueron creadas , se índices para mejorar el rendimiento de las consultas y se crearon vistas para reporte para simplificar las consultas y hacer que los reportes sean más accesibles.
A continuación de muestran las consultas que se generaron como ejemplo para una visualización de reportes en base a las tablas creadas obtenidas de los datos de Coingecko. Se subio un archivo con imagenes de las tablas creadas por estas cosultas al igual que todo el archivo generado en postgreSQL.

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



