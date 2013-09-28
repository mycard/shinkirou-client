# UDP穿越客户端连接
udp = require 'dgram'
EventEmitter = require('events').EventEmitter
log = require '../log'
decode_msg = require('./util').decode_msg

# 设有两只想要联网 A B, 借助在公网的服务 S 可以获取到自身的 Key(K) 和 外网 端口(P)
# 穿透流程：
# A(P) => S(K, P, P) => B(K) => S(K, P, P) => B(K,P) => Done.
# B(P) => S(K, P, P) => A(K) => S(K, P, P) => A(K,P) => Done.

# 一个client代表一个能互通的管道
class tun_client extends EventEmitter
	constructor: (args) ->
		# 需要知道以下参数：
		# 远程Key / 穿透端口 / 本地端口 (预设为同一个端口不同IP绑定)
		{ @Key, @RKey, @LHost, @LPort, @SHost, @SPort, @LBind, @LMap } = args
		@Key   ?= 0
		@RKey  ?= parseInt '0xBADADD1E'
		@LHost ?= '127.0.0.1'
		@LPort ?= 10701
		@LBind ?= 10700 #本地代理端口
		@LMap  ?= 10800 #本地转发端口，根据上次收到端口变化？
		@SHost ?= '116.255.216.22'
		@SPort ?= 10700

	on_receive_local_key: (msg, rinfo)=>
		clearTimeout @watch_timer
		@Local_Map = decode_msg msg
		@Key = @Local_Map.key if @Key == 0

		log "接收到自身映射：", @Local_Map

		this.emit 'local_key', @Local_Map, this if @Key == @Local_Map.key
		@socket.removeListener 'message', @on_receive_local_key

	query_key: (key) ->
		# 开始查询对方Key
		@socket.removeAllListeners 'message'
		@socket.on 'message', @on_query_key

		@RKey = key

		buffer = new Buffer 4
		buffer.writeUInt32LE @RKey, 0
		@socket.send buffer, 0, buffer.length, @SPort, @SHost

	on_query_key: (msg, rinfo)=>
		# 查询到对方Key，准备尝试连接
		@Remote_Map = decode_msg msg
		log "接收到对方映射：", @Remote_Map

		@query_map()

	query_map: =>
		# 尝试与对方UDP进行通信
		@socket.removeAllListeners 'message'
		@socket.on 'message', @on_receive_nya

		@nya_buf = new Buffer 4
		#@nya_buf.write 'nya', 0, 3
		@nya_buf.writeUInt32LE @RKey, 0

		@RHost = @Remote_Map.remote.ip
		@RPort = @Remote_Map.remote.port

		@watch_timer = setInterval =>
			@socket.send @nya_buf, 0, @nya_buf.length, @RPort, @RHost
			@RPort += 1
			@RPort = 1 if @RPort > 65535
		, 200

	on_receive_nya: (msg, rinfo)=>
		# 成功收到Nya包，表示已经可以通信了
		# 立即反馈一个Nya包，记录对方IP:端口给绑定用
		return if msg.length != 4

		key = msg.readUInt32LE 0

		return if key != @Key

		log "Nya!", rinfo

		clearTimeout @watch_timer
		@socket.removeAllListeners 'message'
				
		@RHost = rinfo.address
		@RPort = rinfo.port

		#log msg, rinfo

		# 开始绑定本地端口准备通信
		@client = udp.createSocket "udp4"

		@client.on 'message', @on_local_receive

		@client.on 'error', (msg) ->
			log "本地端口错误", msg

		@client.bind @LBind, 'localhost', =>
			log "本地监听端口：#{@LBind}"
			@socket.on 'message', @on_remote_receive

		@socket.send @nya_buf, 0, @nya_buf.length, @RPort, @RHost

	on_local_receive: (msg, rinfo)=>
		# 转发给远程UDP端
		@socket.send msg, 0, msg.length, @RPort, @RHost
		@LMap = rinfo.port if @LMap == 10800

	on_remote_receive: (msg, rinfo)=>
		# 转发给本地UDP端
		@client.send msg, 0, msg.length, @LMap, 'localhost'

	run: ->
		@socket = udp.createSocket "udp4"

		@socket.on "message", @on_receive_local_key
			#@socket.send @buffer, 0, 4, @port, @host if (@count += 1) < 10

		@socket.on 'error', (msg) =>
			log "UDP错误", msg
			@emit 'error', msg

		@socket.bind @LPort, @LHost, =>
			log "服务启动成功：#{@LHost}:#{@LPort}"
			buffer = new Buffer 10
			buffer.writeUInt32LE @Key, 0
			buffer.writeUInt8 v, i + 4 for v, i in @LHost.split '.'
			buffer.writeUInt16LE @LPort, 8
			@socket.send buffer, 0, buffer.length, @SPort, @SHost

		@socket.on 'close', =>
			@emit 'close'

		# 发起连接后10s内没有反馈则直接认为自己没能成功连接
		@watch_timer = setTimeout =>
			@socket.close()
		, 10000

run = (args) ->
	client = new tun_client args
	client.run()

module.exports = tun_client
module.exports.run = run