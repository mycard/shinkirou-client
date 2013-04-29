udp = require 'dgram'
log = require '../../log'
argv = process.argv

# 僅僅是用來测试一下UDP信息而已
class udp_proxy
	constructor: (args) ->
		{@host, @port, @bind, @local} = args
		@host ?= 'localhost'
		@port ?= 5000
		@bind ?= 495
		@local ?= '0.0.0.0'

		@mport ?= 2333
		@mhost ?= 'localhost'

	run: ->
		@socket = udp.createSocket 'udp4'
		@client = udp.createSocket 'udp4'

		@socket.on "message", (msg, rinfo) =>
			@client.send msg, 0, msg.length, @port, @host
			@mhost = rinfo.address
			@mport = rinfo.port

		@client.on "message", (msg) =>
			@socket.send msg, 0, msg.length, @mport, @mhost		

		@socket.on 'error', (msg) ->
			log "监听UDP错误", msg

		@client.on 'error', (msg) ->
			log "连接UDP错误", msg

		@socket.bind @bind, @local, =>
			log "服务启动成功：#{@local}:#{@bind}"

		@client.bind @bind + 1, @local, =>
			log "连接启动成功：#{@local}:#{@bind + 1}"

run = (host, port, bind)->
	log host, port, bind
	service = new udp_proxy 
		port: port
		host: host
		bind: bind
	service.run()

module.exports = udp_proxy
module.exports.run = run

if argv.length >= 5
	log argv
	run argv[2], (parseInt argv[3]), (parseInt argv[4])

