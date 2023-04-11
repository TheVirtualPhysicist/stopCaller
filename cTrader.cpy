import requests
from math import floor
from binance.spot import Spot
import os
from time import sleep, time

class Trader:
	def __init__(self):
		self.api_key = os.environ['API_KEY']
		self.api_sec = os.environ['API_SEC']
		self.client = Spot(key=self.api_key, secret=self.api_sec)
		self.exchange = "SOL"

		# portfolio statistics
		self.staticMoney = 5
		self.staticCrypto = 0.71928 # 45 eur roughly
		self.money = 0
		self.stocks = 0
		print("b4")
		self.get_balance()
		print("b5")

	def get_price(self):
		return float(requests.get(f'https://api.binance.com/api/v3/ticker/price?symbol={self.exchange}EUR').json()["price"])

	def get_balance(self):
		params = {
			'recvWindow': 60000
		}
		v = self.client.account(**params)["balances"]
		money = 0
		stocks = 0
		# da controllare
		for i in v:
			if i["asset"] == self.exchange:
				stocks = float(i["free"])-self.staticCrypto
			if i["asset"] == "EUR":
				money = float(i["free"])-self.staticMoney
		self.money = money
		self.stocks = stocks
		return money,stocks

	def checkPosition(self):
		self.get_balance()
		if self.stocks>0.05:
			return "long"
		if self.stocks<-0.05:
			return "short"
		return "-"

	def buy_amount(self):
		params_order = {
			'symbol': f"{self.exchange}EUR",
			'side': 'BUY',
			'type': 'MARKET',
			'quantity': self.stocks,
			'recvWindow': 60000
		}
		v = "-"
		verr = "-"
		try:
			v = self.client.new_order(**params_order)
		except Exception as e:
			verr = str(e)
		return f"{v} | {verr}"

	def sell_amount(self):
		params_order = {
			'symbol': f"{self.exchange}EUR",
			'side': 'SELL',
			'type': 'MARKET',
			'quantity': self.stocks,
			'recvWindow': 60000
		}
		v = "-"
		verr = "-"
		try:
			v = self.client.new_order(**params_order)
		except Exception as e:
			verr = str(e)
		return f"{v} | {verr}"