request = require('request');
dgram = require('dgram');

request url:"http://my-card.in:10802/", json: true, (error, response, body)->
  client = dgram.createSocket('udp4')
  done = false
  sent = 0
  client.on 'message', (message)->
    console.log message
    if done
      console.log 'done, create shinrirou host on 10802'
      process.exit()

  client.bind 10810, null, ->
    message = new Buffer('hello')
    for port in body
      client.send message, 0, message.length, port, '72.46.136.253', ->
        sent++
        if sent == body.length
          done = true



#server = dgram.createSocket('udp4')
#first_port = null
#second_port = null
#server.on 'message', (message, remote)->
#  console.log remote.port, message.length, message
#  if !first_port
#    server.send new Buffer("\x04"), 0, 1, remote.port, remote.address
#    first_port = remote.port
#  else if !second_port and first_port != remote.port
#    server.send new Buffer("\x04"), 0, 1, remote.port, remote.address
#    server.send new Buffer("\x04"), 0, 1, remote.port, remote.address
#    second_port = remote.port
#
#server.bind 10807



#client1 = dgram.createSocket('udp4')
#client2 = dgram.createSocket('udp4')

#hello = new Buffer "\x07\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
##msg1 = new Buffer "\x07\x00\x00\x00\x02\x00\x2a\x3a\xc0\xa8\x01\x7e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x01\x00"
#msg1 = new Buffer "\x07\x00\x00\x00\x02\x00\x2a\x37\xc0\xa8\x01\x7e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x01\x00"
##msg2 = new Buffer "\x07\x00\x00\x00\x02\x00\x2a\x37\xc0\xa8\x01\x7e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x4b\xf2"
#msg2 = new Buffer "\x07\x00\x00\x00\x02\x00\x2a\x37\xc0\xa8\x01\x7e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x24\xee"
#
#client1.on 'message', (message, remote)->
#  console.log message
#client2.on 'message', (message, remote)->
#  console.log message
#
#speak = ->
#  client1.send(hello, 0, hello.length, 10807, "192.168.1.220")
#  client2.send(hello, 0, hello.length, 10807, "192.168.1.220")
#  client1.send(msg1, 0, msg1.length, 10807, "192.168.1.220")
#  client1.send(msg2, 0, msg2.length, 10807, "192.168.1.220")
#  client2.send(msg2, 0, msg2.length, 10807, "192.168.1.220")
#
#client1_binded = false
#client2_binded = false
#
#client1.bind 12345, null, ->
#  client1_binded = true
#  if client2_binded
#    speak()
#
#client2.bind 12346, null, ->
#  client2_binded = true
#  if client1_binded
#    speak()