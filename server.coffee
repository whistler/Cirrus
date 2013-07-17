ss = require('socket.io-stream')
path = require('path')
fs = require('fs')

global.config = require('./config/server')
auth = require('./auth')
util = require('./util')

sockets = {}

# check if filestore exists
fs.exists(global.config.filestore, (exists) ->
  if exists
    console.log('Storing files in ' + global.config.filestore)
  else
    console.log('Error ' + global.config.filestore + ' does not exist')
    process.exit(-1)
)

# persistent connection for events
socket = require('socket.io')(global.config.port)
console.log("Listening...")

socket.on('connection', (socket) ->
  console.log("connected")

  socket.on('auth', (data) ->
    console.log(data)
    token = auth.authenticate(data['username'], data['password'])
    if token
      sockets[socket] = data['username']
      socket.emit('token', token) 
    else 
      socket.emit('unauthorized')
  )

  ss(socket).on('update', (stream, data) ->
    if (user = auth.valid(data.token))
      filename = path.join(global.config.filestore,user,path.basename(data.name))
      util.ensure_folder_exists(path.join(global.config.filestore,user))
      stream.pipe(fs.createWriteStream(filename))
    else
      socket.emit('unauthorized')
  )
  
  socket.on('disconnect', ()->
    delete sockets[socket]
  )
  
)