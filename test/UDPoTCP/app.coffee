# 单纯测试一下XQL的数据代理，看能否直接代理通过
udp = require "dgram"
tcp = require "net"
log = console.log 

class client_UDP2TCP
	constructor: (args) ->
		# 将UDP悉数转发给TCP的蛋疼连接端
		@udp_bind = {}
		@tcp_client = {}

		@udp_bind.address = args.udp_bind.address ? "localhost"
		@udp_bind.port = args.udp_bind.port ? 10700
		@tcp_client.port = args.tcp_client.port ? 10010 
		@tcp_client.host  = args.tcp_client.host ? "localhost"
		#log "服务端： #{@tcp_client.port}"

	run: ->
		# 首先连接到TCP端口
		log "服务端： #{@tcp_client.host}:#{@tcp_client.port}"
		log "客户端： #{@udp_bind.port}"
		@client = tcp.connect @tcp_client.port, @tcp_client.host, =>
			log "连接成功，监听本地UDP#{@udp_bind.port}"

			@read_buffer = new Buffer 0

			@server = udp.createSocket "udp4"

			@server.on "message", (msg, rinfo) =>
				# 每收到一个UDP包⑨打包一个给TCP发出去
				#log "源：#{rinfo.port}, 长: #{msg.length}"

				# 包字节顺序：[2字节长度][2字节端口][数据]
				write_pkg = new Buffer 4+msg.length
				write_pkg.writeUInt16BE msg.length, 0
				write_pkg.writeUInt16BE rinfo.port, 2
				msg.copy write_pkg, 4

				# 发包 TCP
				# log "发包: #{write_pkg.length}"
				@client.write write_pkg

			@server.on 'error', (msg) =>
				log "UDP错误，信息:#{msg}"

			@server.bind @udp_bind.port, @udp_bind.host , =>
				log "UDP绑定成功"
				@client.start

		@client.on 'data', (data) =>
			# 包字节顺序：[2字节长度][2字节端口][数据]
			@read_buffer = Buffer.concat [@read_buffer, data]

			# 检查包头，如果不足4字节则返回继续等
			while @read_buffer.length > 4
				# 检查包长，如果不足包长则继续返回等
				len  = @read_buffer.readUInt16BE 0
				return if @read_buffer.length < len + 4

				# 读取端口，准备发送
				port = @read_buffer.readUInt16BE 2
				@server.send @read_buffer, 4, len, port, "localhost"

				# 切包
				@read_buffer = @read_buffer.slice len+4


		@client.on 'end', =>
			# 异常直接导致退出，毕竟是测试程序
			@client.unref
			@server.close if @server?

		@client.on 'error', (msg) =>
			log "连接异常，错误：#{msg}"


class server_TCP2UDP
	constructor: (args) ->
		# 将TCP还原成UDP包
		@tcp_bind = {}
		@udp_client = {}

		@tcp_bind.port = args.tcp_bind.port ? 10010
		@udp_client.addr = args.udp_client.addr ? "localhost"
		@udp_client.port = args.udp_client.port ? 10800

	run: ->
		log "tcp端口: #{@tcp_bind.port}"
		@clients = []
		# 首先建立TCP监听
		@server = tcp.createServer (@socket)=>
			log "连接到来: #{@socket.address()}"
			@socket.read_buffer = new Buffer 0

			# 监听到连接数据后，开始拆包数据
			@socket.on 'data', (data) =>
               		# 包字节顺序：[2字节长度][2字节端口][数据]
        			@socket.read_buffer = Buffer.concat [@socket.read_buffer, data]
               		
               		# 检查包头，如果不足4字节则返回继续等
        			while @socket.read_buffer.length > 4
        				# 检查包长，如果不足包长则继续返回等
        				len  = @socket.read_buffer.readUInt16BE 0
        				return if @socket.read_buffer.length < len + 4

        				# 读取端口，准备发送
        				port = @socket.read_buffer.readUInt16BE 2
        				#port += 1

        				#log "源：#{port}, 长：#{len}"

        				# 根据拆包端口建立udp bind 并发送数据到指定地址
        				if @clients[port]? #and @clients[port].active
        					@clients[port].send @socket.read_buffer, 4, len, @udp_client.port, "localhost"
        				else
        					client_pkg =  @socket.read_buffer.slice 4, len + 4
        					@clients[port] = client = udp.createSocket "udp4"
        					@clients[port].active = false
        					client.on "message", (msg, rinfo) =>
        						# 每收到一个UDP包⑨打包一个给TCP发出去
        						#log "源：#{rinfo.port}, 长: #{msg.length}"

        						# 包字节顺序：[2字节长度][2字节端口][数据]
        						write_pkg = new Buffer 4+msg.length
        						write_pkg.writeUInt16BE msg.length, 0
        						write_pkg.writeUInt16BE port, 2 # 注意这里应该放代理的Port
        						msg.copy write_pkg, 4

        						# 发包 TCP
        						#log "发包: #{write_pkg.length}"
        						@socket.write write_pkg

        					client.on 'error', (msg) =>
        						log "UDP错误，信息:#{msg}"
        						#@clients[port] = null
        						#client.unref
        						#client.close

        					client.bind @udp_bind , =>
        						log "UDP绑定成功"
        						#@clients[port].active = true
        						#client.send client_pkg, 0, client_pkg.length, @udp_client.port, "localhost"
        						#@client.start

        				# 切包
        				@socket.read_buffer = @socket.read_buffer.slice len+4

        	@socket.on 'error', (msg) ->
        		log "客户端出错， #{msg}"
				
		@server.on 'error', (msg) =>
			log "服务端出错，信息 #{msg}"
			@server.unref

		@server.listen @tcp_bind.port, =>
			log "服务端已经建立"

if process.env.IS_SERVER
	app = new server_TCP2UDP
		tcp_bind:
			port: 10010
		udp_client:
			addr: "127.0.0.3"
			port: 10800
else
	app = new client_UDP2TCP
		udp_bind:
			address: "127.0.0.2"
			port: 10700
		tcp_client:
			#host: "119.167.70.210"
			port: 10010

#导出模块对象
exports.app = app
exports.run = ->
        app.run()