# load configuration file
config = require('./config/server')
auth = require('./auth')
fs = require('fs')
util = require('./util')

# check if filestore exists
fs.exists(config.filestore, (exists) ->
  if exists
    console.log('Storing files in ' + config.filestore)
  else
    console.log('Error ' + config.filestore + ' does not exist')
    process.exit(-1)
)

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
      filename = path.join(config.filestore,user,path.basename(data.name))
      util.ensure_folder_exists(path.join(config.filestore,user))
      console.log(filename)
      stream.pipe(fs.createWriteStream(filename))
    else
      socket.emit('unauthorized')
  )
  
)
