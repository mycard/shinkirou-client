udp = require 'dgram'
log = require '../log'

# 僅僅是用來测试一下UDP信息而已
class udp_test
	constructor: (args) ->
		{@host, @port, @bind, @local} = args
		@host ?= 'localhost'
		@port ?= 5000
		@bind ?= 495
		@local ?= 'localhost'

		@count = 0

		@socket = udp.createSocket "udp4"

	run: ->
		@socket.on "message", (msg, rinfo) =>
			log msg, rinfo
			msg.copy @buffer, 0, 0, 4
			@socket.send @buffer, 0, 4, @port, @host if (@count += 1) < 10

		@socket.on 'error', (msg) ->
			log "UDP错误", msg

		@socket.bind @bind, @local, =>
			log "服务启动成功：#{@local}:#{@bind}"
			@buffer = new Buffer 10
			@buffer.writeUInt32LE 0, 0
			@buffer.writeUInt8 v, i + 4 for v, i in @local.split '.'
			@buffer.writeUInt16LE @bind, 8
			@socket.send @buffer, 0, @buffer.length, @port, @host

		setTimeout =>
			@socket.close()
		, 1000

run = (port, host, bind, local)->
	service = new udp_test 
		port: port
		host: host
		bind: bind
		local: local
	service.run()

module.exports = udp_test
module.exports.run = run

#嘗試獲取本地IP
os = require 'os'
ifaces = os.networkInterfaces()

#log dev, ips for dev, ips of ifaces
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
for dev, ips of ifaces
	for ip in ips
		log ip
		run 10700, 'localhost', 495, ip.address if ip.family is 'IPv4' 

