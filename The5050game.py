import MetaTrader5 as mt5
import pandas as pd
import numpy as np
import pytz
from datetime import datetime
from datetime import timedelta

pd.set_option('display.max_rows', None)
pd.options.display.width = None
pd.options.display.float_format = "{:,.2f}".format

# establish connection to MetaTrader 5 terminal
if not mt5.initialize():
    print("initialize() failed, error code =",mt5.last_error())
    quit()

account = 12345678
authorized = mt5.login(account, password="password", server="yourServer")
if not authorized:
    print("failed to connect at account #{}, error code: {}".format(account, mt5.last_error()))

# set time zone to UTC
timezone = pytz.timezone("Etc/UTC")

# select symbol
selected=mt5.symbol_select("Ger40",True)
if not selected:
    print("failed to select symbol")
    mt5.shutdown()
    quit()

# create 'datetime' object in UTC time zone to avoid the implementation of a local time zone offset
utc_from = datetime(2017, 2, 12, tzinfo=timezone)
utc_to = datetime(2022, 11, 17, tzinfo=timezone)

# get the bar data
rates = mt5.copy_rates_range("Ger40", mt5.TIMEFRAME_M1, utc_from, utc_to)

# shut down connection to the MetaTrader 5 terminal
mt5.shutdown()

# put received rates into dataframe
df_raw = pd.DataFrame(rates)

# convert time in seconds into the datetime format
df_raw['time']=pd.to_datetime(df_raw['time'], unit='s')

print(df_raw)

# count bull and bear bars
all_bars = len(df_raw.index)
bulls = 0
bears = 0
for pos, d in df_raw.iterrows():
    if(d.close > d.open):
        bulls += 1
    elif(d.close < d.open):
        bears += 1

print(f'\nAll bars in given timeframe: {all_bars}')
print(f'Bull bars in given timeframe: {bulls} {bulls*100/all_bars:.0f}%')
print(f'Bear bars in given timeframe: {bears} {bears*100/all_bars:.0f}%')
