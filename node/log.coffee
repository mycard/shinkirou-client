util = require 'util'
#ansi = require 'ansi'
#cursor = ansi process.stdout

#借助util, log 现在支持各种Object\String\Number了喵～
log = (msg...) ->
    util.log "#{util.format msg}"

debug = (msg...) ->
	util.debug "#{util.format msg}"

error = (msg...) ->
	util.error "#{util.format msg}"
    
module.exports = log
module.exports.debug = debug
module.exports.error = error

#借助ansi，log 现在支持就地数据更新了喵～
