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

		@client_count = @client_len = 0
		@socket_count = @socket_len = 0

	first_packet: (msg, rinfo)=>
		@mhost = rinfo.address
		@mport = rinfo.port
		
		@socket.removeAllListeners 'message'
		
		@socket.on 'message', @redirect_packet
		@client.on "message", (msg, rinfo) =>
			@socket.send msg, 0, msg.length, @mport, @mhost

		@client.resume()
		@socket.resume()

		#@client.send msg, 0, msg.length, @port, @host

		log @mhost, @mport
		setInterval =>
			log "C:#{@client_len}/#{@client_count} \t\t S:#{@socket_len}/#{@socket_count}"
			@client_count = @client_len = 0
			@socket_count = @socket_len = 0
		, 1000

	redirect_packet: (msg, rinfo)=>
		@client.send msg, 0, msg.length, @port, @host #if rinfo.port == @mport

		#@socket.send msg, 0, msg.length, @mport, @mhost

	run: ->
		@socket = udp.createSocket 'udp4'
		@client = udp.createSocket 'udp4'

		@socket.on "message", @first_packet

		@socket.on 'error', (msg) ->
			log "监听UDP错误", msg

		@client.on 'error', (msg) ->
			log "连接UDP错误", msg

		@socket.bind @bind, @local, =>
			log "服务启动成功：#{@local}:#{@bind}"

		@client.bind @bind + 1, '0.0.0.0', =>
			log "连接启动成功：0.0.0.0:#{@bind + 1}"

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
	run argv[2], (parseInt argv[3]), (parseInt argv[4])
