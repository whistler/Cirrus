# Cirrus Server
global.app = 'server'
global.config = require('./config/server')
Common = require './common'
global.socket = null

synchronizer = require('./server_synchronizer')
Watcher = require('./server_watcher')

Common.util.exit_if_missing(global.config.filestore, "Configuration file missing.")
console.log('Storing files in ' + global.config.filestore)

# List for clients
socketio = require('socket.io').listen(global.config.port, {'log':false})
console.log("Listening...")

socketio.on('connection', (socket) ->
  console.log("Connected: " + socket.id)
  watcher = null
  # authenticate user
  socket.on('auth', (params) ->
    token = Common.auth.authenticate(params.username, params.password)
    if token # successfully logged in
      socket.emit('authenticated', token)
      console.log(params.username + " logged in")
      watcher = new Watcher(synchronizer, global.config.filestore, socket, params.username)
      socket.emit('fetch_list')
    else 
      socket.emit('unauthorized')
  )
  
  # request from client to get a specific file
  socket.on('get', (params) ->
    if (user = Common.auth.valid(params.token))
      file_path = Common.path.join(global.config.filestore, user, params.file)
      stream = Common.stream.createStream()
      stat = Common.fs.statSync(file_path)
      Common.stream(socket).emit('update', stream, {file: params.file, token: global.auth_token, time: stat.mtime, last_updated: stat.mtime}) 
      Common.fs.createReadStream(file_path).pipe(stream)
      console.log("Uploading: " + file_path)
    else
      socket.emit('unauthorized')
  )
  
  # receive updated list of files on client with their timestamps
  socket.on('list', (params) ->
    if (user = Common.auth.valid(params.token))
      console.log('recieved list from ' + user)
      synchronizer.sync(params.list, watcher, socket, user)
      # check which files need to be updated and emit 'get' on them
    else
      socket.emit('unauthorized')    
  )
  
  # send a list of files for user to client
  socket.on('fetch_list', (params) ->
    if (user = Common.auth.valid(params.token))
      path = Common.path.join(config.filestore, user)
      Common.util.directory(path, (files) ->
        socket.emit('list', {list: files})
      )
  )

  # recieve file updates from client
  Common.stream(socket).on('update', (stream, params) ->
    if (user = Common.auth.valid(params.token))
      synchronizer.get(stream, params, user, socket, watcher)
    else
      socket.emit('unauthorized')
  )
  
  # client reports file recieved successfully
  socket.on('update_success', (params) ->
    if (user = Common.auth.valid(params.token))
      watcher.set_timestamp(params.file, params.time)
    else
      socket.emit('unauthorized')
  )

  # client gets disconnected
  socket.on('disconnect', () ->
    
  )
 
)