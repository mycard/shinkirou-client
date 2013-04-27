# 心绮楼客户端 主程序
log = require './log'

log "hello,world",
	a: 1
	b: 2
	c: "string"
	d:
		o: "object"
	, 12321
	, log

log.debug "debug info"
log.error "Error!System Exit!"
