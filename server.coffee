# Cirrus Server
global.app = 'server'
global.config = require('./config/server')
global.serv = global.config.servers[global.config.current_server]
Common = require './common'

# GOTO LINE 98 FOR OLD CODE

# Connect to other server as client
sclient = require('socket.io-client')
ssocket = sclient.connect("http://" + global.serv.host + ":" + global.serv.port, {'transports':['websocket']})
ssynchronizer = require('./p2p_synchronizer') # sends updates to other server
ssynchronizer.set_socket(ssocket)
swatcher = require('./watcher')
swatcher.start(ssynchronizer, global.config.filestore)
ssocket.on('connect', () ->
  console.log('Connected to Server! ' + global.serv.server)
  ssocket.emit('fetch_list')
)
# receive updated list of files on this from other server with their timestamps
ssocket.on('list', (params) ->
  console.log('recieved list from ' + global.config.current_server)
  Common.util.directory(config.filestore, (files) ->
    sync(params.list, files, ssocket)
  )
)
ssocket.on('disconnect', () ->
  console.log('Server Disconnected')
#  next_server()
)
ssocket.on('error', (err) ->
  console.log(err)
  console.log("TODO: Try to reconnect after timeout")
#  next_server()
)
# Send file that server requests
ssocket.on('get', (params) ->
  file_path = Common.path.join(Common.util.expand(global.config.directory), params.file)
  stream = Common.stream.createStream()
  stat = Common.fs.statSync(file_path)
  Common.stream(socket).emit('update', stream, {name: params.file, token: global.auth_token, mtime: stat.mtime}) 
  Common.fs.createReadStream(file_path).pipe(stream)
  console.log("Uploading: " + file_path)
)
# sends list of files in directory to sever
ssocket.on('fetch_list', (params) ->
  console.log('Sending list to other server')
  path = config.filestore
  Common.util.directory(path, (files) ->
    ssocket.emit('list', {list:files})
  )
)

# For Client to this Server
csocketio = require('socket.io').listen(global.config.lport, {'log':false})
console.log(global.config.server + " is Listening...")

csocketio.on('connection', (csocket) ->
  console.log("Connected: " + csocket.id)
  csocket.emit('fetch_list')
  
  # request from client to get a specific file
  csocket.on('get', (params) ->
    file_path = Common.path.join(global.config.filestore, params.file)
    stream = Common.stream.createStream()
    stat = Common.fs.statSync(file_path)
    Common.stream(csocket).emit('update', stream, {name: params.file, mtime: stat.mtime}) 
    Common.fs.createReadStream(file_path).pipe(stream)
    console.log("Uploading: " + file_path)
  )
    
  # send a list of files for user to client
  csocket.on('fetch_list', (params) ->
    path = Common.path.join(config.filestore)
    Common.util.directory(path, (files) ->
      csocket.emit('list', {list:files})
    )
  )

  # client gets disconnected
  csocket.on('disconnect', () ->
    console.log('disconnected')
  )

  # client gets disconnected
  csocket.on('error', () ->
    console.log('error')
  )
 
  # provide client all updates since last update
  csocket.on('fetch_updates', (params) ->
    directory = Common.path.join(global.config.filestore)
  )
)

# OLD CODE FROM HERE ONWARDS


synchronizer = require('./server_synchronizer')
Watcher = require('./server_watcher')

Common.util.exit_if_missing(global.config.filestore, "Configuration file missing.")
console.log('Storing files in ' + global.config.filestore)

# List for clients
socketio = require('socket.io').listen(global.config.port, {'log':false})
console.log(global.config.server + " is Listening...")

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
    else
      socket.emit('unauthorized')
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
