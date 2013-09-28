EventEmitter = require('events').EventEmitter
log = require '../log'
client = require './tun_client'

#管理本地映射端口和UDP穿透连接(NAT客户端)
class TUN_CLIENT_MANAGE extends EventEmitter
	constructor: (args) ->
		#需要以下参数
		#1.本地映射端口 
		#2.本地目标端口