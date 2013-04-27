udp = require 'dgram'
log = require '../log'

# 部署在公网的 Tun Server 负责将想要穿透的两端UDP进行交换
class tun_server
	constructor: (args) ->
		{ @host, @port, @clearInterval, @clearCount } = args

		@host ?= '0.0.0.0'			# 默认监听所有IP地址
		@port ?= 5000				# 默认监听5000端口
		@clearInterval ?= 300000 	# 默认 5分钟 清理一次
		@clearCount ?= 5000 		# 默认收到 5K 请求后清理一次

		@client_list = {}			# 保存默认映射表
		@client_list_count = 0		# 保存新映射数量
		@client_list_last = {}		# 保存上次映射表

		@server = udp.createSocket "udp4"

	clearList: ->
		@client_list_last = @client_list
		@client_list = {}
		@client_list_count = 0

	run: ->
		@server.on "message", (msg, rinfo) =>
			return if msg.length < 4

			key = msg.readUInt32LE 0
			log "Key:#{key}", rinfo
			#return if rinfo.family != 'IPv4'

			# 1.客户端发送自身Key和IP给Server，Server返回公网IP和Port给客户端，并记录该客户端
			# 客户端发送包(10char) [4char Key][4char IP][2char Port]
			# 服务端应答包(16char) [4char Key][4char IP][2char Port][4char Public IP][2char Public port]
			if msg.length == 10
				buf = new Buffer 16

				msg.copy buf, 0
				buf.writeUInt8 v, i + 10 for v, i in rinfo.address.split '.'
				buf.writeUInt16LE rinfo.port, 14

				@client_list_count += 1 if !(@client_list[key]?)
				@client_list[key] = buf

				#到达最大缓存后，也进行清理操作，防止一时间大量请求
				if @client_list_count > @clearCount 
					setImmediate => clearList() 

			# 2.客户端询问某个Key对应的IP和Port，服务器返回对方信息
			# 客户端发送包( 4char) [4char Key]
			# 客户端发送包(16char) [4char Key][4char IP][2char Port][4char Public IP][2char Public port]
			if msg.length == 4
				buf = @client_list[key] ? @client_list_last[key] ? null

			#反馈客户端对应包
			@server.send buf, 0, buf.length, rinfo.port, rinfo.address if buf?

		# 3.服务端每隔一定时间会将表进行清理操作，避免大量内存占用
		setInterval =>
			clearList()
		, @clearInterval

		@server.on 'error', (msg) ->
			log "UDP错误", msg

		@server.bind @port, @host , =>
			log "服务启动成功：#{@host ? '0.0.0.0'}:#{@port}"

run = (port, host)->
	service = new tun_server 
		port: port
		host: host
	service.run()

# IPv4 地址字符串 和 Buffer 转换函数
split_IPv4_Buffer = (address) ->
	arr = address.split '.'
	null if arr.length != 4
	buf = new Buffer 4
	#buf.writeUInt8 a[i], i for i in [0..3]
	buf.writeUInt8 a[0], 0
	buf.writeUInt8 a[1], 1
	buf.writeUInt8 a[2], 2
	buf.writeUInt8 a[3], 3
	buf

module.exports = tun_server
module.exports.run = run

#run 10700, "127.0.0.1"