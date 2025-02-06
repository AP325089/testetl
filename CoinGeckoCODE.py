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