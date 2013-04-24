zlib = require 'zlib'
fs = require 'fs'
log = console.log
argv = process.argv

return if argv.length < 4

# 从第4字节开始读取是因为前4个字节表示的是压缩包长度
dat_file = fs.createReadStream argv[2],
	start: 4
unzip_file = fs.createWriteStream argv[3]
unzip = zlib.createUnzip()

(dat_file.pipe unzip).pipe unzip_file