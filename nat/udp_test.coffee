udp = require 'dgram'
log = require '../log'

# 僅僅是用來测试一下UDP信息而已
class udp_test
	constructor: (args) ->
		{@host, @port, @bind} = args
		@host ?= 'localhost'
		@port ?= 5000
		@bind ?= 495

		@socket = udp.createSocket "udp4"

	run: ->
		@socket.on "message", (msg, rinfo) =>
			log msg, rinfo

		@socket.on 'error', (msg) ->
			log "UDP错误", msg

		@socket.bind @bind, 'localhost', =>
			log "服务启动成功：#{@bind}"
			@buffer = new Buffer 10
			@socket.send @buffer, 0, @buffer.length, @port, @host
			@socket.send @buffer, 0, 4, @port, @host


run = (port, host, bind)->
	service = new udp_test 
		port: port
		host: host
		bind: bind
	service.run()

module.exports = udp_test
module.exports.run = run

#嘗試獲取本地IP
os = require 'os'
ifaces = os.networkInterfaces()

log dev, ips for dev, ips of ifaces
#for dev, ips of ifaces
#	setTimeout (d, i) ->
#		log d, i
#	, 100, dev, ips
#	setTimeout new ->
#		@d = dev
#		@i = ips
#		=>
#			log @d, @i
#	, 100

#_ = require 'underscore'
#_.each ifaces, (dev, ips)->
#	setTimeout ->
#		log dev, ips
#	, 100


#run 10700, "localhost", 495

