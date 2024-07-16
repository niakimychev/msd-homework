from flask import Flask, jsonify
import requests
import sqlite3
import pandas as pd
import datetime
import time
import threading

app = Flask(__name__)

API_URL = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=eur,czk"
DATABASE = 'bitcoin_prices.db'

def init_db():
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS prices (
        id INTEGER PRIMARY KEY,
        btc_eur REAL,
        btc_czk REAL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    ''')
    conn.commit()
    conn.close()

def fetch_btc_price():
    response = requests.get(API_URL)
    data = response.json()
    return data['bitcoin']['eur'], data['bitcoin']['czk']

def store_btc_price():
    btc_eur, btc_czk = fetch_btc_price()
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('INSERT INTO prices (btc_eur, btc_czk) VALUES (?, ?)', (btc_eur, btc_czk))
    conn.commit()
    conn.close()

def calculate_averages():
    conn = sqlite3.connect(DATABASE)
    df = pd.read_sql_query("SELECT * FROM prices", conn)
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    daily_avg = df.resample('D', on='timestamp').mean().tail(1).to_dict('records')[0]
    monthly_avg = df.resample('M', on='timestamp').mean().tail(1).to_dict('records')[0]
    conn.close()
    return daily_avg, monthly_avg

def background_task():
    while True:
        store_btc_price()
        time.sleep(300)

@app.route('/current_price', methods=['GET'])
def current_price():
    btc_eur, btc_czk = fetch_btc_price()
    return jsonify({
        'btc_eur': btc_eur,
        'btc_czk': btc_czk,
        'currency': 'BTC',
        'request_time': datetime.datetime.utcnow().isoformat()
    })

@app.route('/averages', methods=['GET'])
def averages():
    daily_avg, monthly_avg = calculate_averages()
    return jsonify({
        'daily_avg': daily_avg,
        'monthly_avg': monthly_avg,
        'request_time': datetime.datetime.utcnow().isoformat()
    })

if __name__ == '__main__':
    init_db()
    threading.Thread(target=background_task).start()
    app.run(host='0.0.0.0', port=5000)
