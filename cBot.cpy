import discord
from discord.ext import commands
import asyncio
from time import time, sleep
from datetime import datetime, timedelta
import requests
import websocket, json
import threading
import Trader as TraderLib
import sys
from random import random

class Bot:
	def __init__(self):
		self.client = discord.Client()
		self.Trader = TraderLib.Trader()
		self.name = "stopCaller"
		self.SESSION = "run"

		# id canali
		self.room = {'generaleCH':1005242726125678635,
						'attivitaCH':1005245873883713546,
						'transazioniCH':1005968395927293962,
						'azioniCH':1005245915931615393,
						'logCH': 1088737979683590164}

		self.stopLoss = -1
		self.trailingDelta = 0.01 # da modificare in base alla strategia

	async def startConnectionMessage(self):
		greet_message = f"[{self.name}] Starting Connection."
		await self.client.get_channel(self.room['attivitaCH']).send(greet_message)

	async def crashMessage(self,e):
		allowed_mentions = discord.AllowedMentions(everyone = True)
		await self.client.get_channel(self.room['azioniCH']).send(content=str(e), allowed_mentions=allowed_mentions)

	async def runLoop(self):
		position = self.Trader.checkPosition()
		if position == "-":
			self.stopLoss == -1
		if position != "-":
			price = self.Trader.get_price()
			
			# updating stop loss
			if self.stopLoss == -1: # first check of the signal
				if position == "long":
					self.stopLoss = price*(1-self.trailingDelta)
				elif position == "short":
					self.stopLoss = price*(1+self.trailingDelta)
			else:
				if position == "long":
					self.stopLoss = max(self.stopLoss,price*(1-self.trailingDelta))
				elif position == "short":
					self.stopLoss = min(self.stopLoss,price*(1+self.trailingDelta))

			# checking for execution
			if position == "long":
				if price <= self.stopLoss:
					message = self.Trader.sell_amount()
					await self.client.get_channel(self.room['transazioniCH']).send(f"[{self.name}] {message}")
					allowed_mentions = discord.AllowedMentions(everyone = True)
					await self.client.get_channel(self.room['azioniCH']).send(content=f"[{self.name}] @everyone Stock transaction closed.", allowed_mentions=allowed_mentions)
					self.stopLoss == -1
			if position == "short":
				if price >= self.stopLoss:
					message = self.Trader.buy_amount()
					await self.client.get_channel(self.room['transazioniCH']).send(f"[{self.name}] {message}")
					allowed_mentions = discord.AllowedMentions(everyone = True)
					await self.client.get_channel(self.room['azioniCH']).send(content=f"[{self.name}] @everyone Stock transaction closed.", allowed_mentions=allowed_mentions)
					self.stopLoss == -1

			if random()>0.01:
				await self.client.get_channel(self.room['logCH']).send(f"[{self.name}] trailingDelta: {self.stopLoss}")
		await  asyncio.sleep(1) # check every second

