import pycom
import time
import socket
import _thread
from machine import UART,ADC,Pin,idle
from network import WLAN
from LTR329ALS01 import LTR329ALS01

# You need to declare and implement:  mean 
import externals


SSID = 'Network2GHz'
KEY = 'kalenderlys'

wlan = WLAN(mode=WLAN.STA)
nets = wlan.scan()
for net in nets:
	if net.ssid == SSID:
		print('Network found!')
		wlan.connect(net.ssid, auth=(net.sec, KEY), timeout=5000)
		while not wlan.isconnected():
			idle() # save power while waiting
		print('WLAN connection succeeded!')
		print(wlan.ifconfig()) # Print the connection settings, IP, Subnet mask, Gateway, DNS
		break


socketServer = socket.socket()
socketServer.setblocking(True)
socketServer.connect(('192.168.0.16', 8000))

temps = []

p_out = Pin('P19', mode=Pin.OUT)
p_out.value(1)
adc = ADC()             # create an ADC object
apin = adc.channel(pin='P16', attn=2)   # create an analog pin on P16

def th_func0(action):
	while True:
		time.sleep(0.01)
		action()
		
def loop0():
	def expLeft837d534a_279d_4f78_9542_5f55b42f09d9():
		temperature = apin()
		return temperature
	
	
	def expRight837d534a_279d_4f78_9542_5f55b42f09d9(value):
		temps.append(value)
	
	
	result = expLeft837d534a_279d_4f78_9542_5f55b42f09d9()
	expRight837d534a_279d_4f78_9542_5f55b42f09d9(result)

_thread.start_new_thread(th_func0, (loop0,))
def th_func1(action):
	while True:
		time.sleep(0.1)
		action()
		
def loop1():
	def expLeft82b1815f_41ff_42ea_94d2_60a6896837cc():
		return externals.mean(temps)
	
	
	def expRight82b1815f_41ff_42ea_94d2_60a6896837cc(value):
		socketServer.send(bytes(str(value), "utf8"))
	
	
	result = expLeft82b1815f_41ff_42ea_94d2_60a6896837cc()
	expRight82b1815f_41ff_42ea_94d2_60a6896837cc(result)
	global temps
	temps = []

_thread.start_new_thread(th_func1, (loop1,))



