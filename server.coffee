# load configuration file
config = require('./config/server')

fs = require('fs')

# persistent connection for events
io = require('socket.io')(config.port)
console.log("Listening...")

ss = require('socket.io-stream')
path = require('path')

io.on('connection', (socket) ->
  console.log("connected")
  ss(socket).on('update', (stream, data) ->
    filename = path.join(config.filestore,path.basename(data.name))
    console.log(filename)
    stream.pipe(fs.createWriteStream(filename))
  )
)