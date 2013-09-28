decode_msg = (msg) ->
	return null if msg.length < 4

	result = {}

	if msg.length >= 4
		result.key = msg.readUInt32LE 0

	if msg.length >= 10
		result.local = {}
		result.local.ip = (msg[i] for i in [4..7]).join '.'
		result.local.port = msg.readUInt16LE 8

	if msg.length >= 16
		result.remote = {}
		result.remote.ip = (msg[i] for i in [10..13]).join '.'
		result.remote.port = msg.readUInt16LE 14		
	
	result

module.exports.decode_msg = decode_msg