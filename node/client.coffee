# 心绮楼客户端 主程序
log = require './log'
tun_client = require './nat/tun_client'

log "准备连接"

#嘗試獲取本地IP
os = require 'os'
ifaces = os.networkInterfaces()

# 记录联通Key的Client
client_map = {}

for dev, ips of ifaces
	for ip in ips
		log ip if ip.family is 'IPv4' and !ip.internal
		if ip.family is 'IPv4' and !ip.internal
			client = new tun_client
				LHost: ip.address

			client.on 'local_key', (map, c)=>
				#log c, client, this, _this
				client_map[map.key] = c

			client.run()

log "请输入对方Key："
process.stdin.on 'data', (key)->
	rkey = parseInt key
	log "尝试连接对方，Key:#{rkey}"

	for key, client of client_map
		client.query_key rkey

process.stdin.resume()
