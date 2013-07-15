# load configuration file
config = require('./config/server')
auth = require('./auth')
fs = require('fs')

# persistent connection for events
socket = require('socket.io')(config.port)
console.log("Listening...")

ss = require('socket.io-stream')
path = require('path')

socket.on('connection', (socket) ->
  console.log("connected")

  socket.on('auth', (data) ->
    console.log(data)
    token = auth.authenticate(data['username'], data['password'])
    if token 
      socket.emit('token', token) 
    else 
      socket.emit('unauthorized')
  )

  ss(socket).on('update', (stream, data) ->
    if (user = auth.valid(data.token))
      filename = path.join(config.filestore,path.basename(data.name))
      console.log(filename)
      stream.pipe(fs.createWriteStream(filename))
    else
      socket.emit('unauthorized')
  )
  
)