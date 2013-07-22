# Cirrus Server
global.app = 'server'
global.config = require('./config/server')
Common = require('./common')
client = require('socket.io-client')

####################### SERVER - SERVER(P2P) COMMUNICATION ###################

p2psynchronizer = require('./p2p_synchronizer') # sends updates to other server
P2PWatcher = require('./p2p_watcher')
p2pwatcher = new P2PWatcher(p2psynchronizer, global.config.filestore)
p2psynchronizer.set_watcher(p2pwatcher)

# Connection to other servers
server1 = global.config.servers[0]
console.log("Connecting to " + server1.server)
c1socket = client.connect("http://" +  server1.host + ":" + server1.port, {'transports':['websocket'], 'force new connection': true})

c1socket.on('connect', () ->
  console.log('Connected to ' + server1.server)
  c1socket.emit('fetch_list')
  
  # recieve file updates from client
  Common.stream(c1socket).on('update', (stream, params) ->
    p2psynchronizer.get(stream, params, c1socket)
  )
)

c1socket.on('delete', (params) ->
  path = Common.path.join(global.config.filestore, params.file)
  if Common.fs.existsSync(path) then Common.fs.unlinkSync(path)
)

c1socket.on('list',(params)->
  p2psynchronizer.sync(params.list, p2pwatcher, c1socket)
)

server2 = global.config.servers[1]
console.log("Connecting to " + server2.server)
c2socket = client.connect("http://" +  server2.host + ":" + server2.port, {'transports':['websocket'], 'force new connection': true})

c2socket.on('connect', () ->
  console.log('Connected to ' + server2.server)
  c2socket.emit('fetch_list')
  
  # recieve file updates from client
  Common.stream(c2socket).on('update', (stream, params) ->
    p2psynchronizer.get(stream, params, c2socket)
  )
)

c2socket.on('delete', (params) ->
  path = Common.path.join(global.config.filestore, params.file)
  if Common.fs.existsSync(path) then Common.fs.unlinkSync(path)
)

c2socket.on('list',(params)->
  p2psynchronizer.sync(params.list, p2pwatcher, c2socket)
)

# Socket for other servers to connect to
global.ssocketio = require('socket.io').listen(global.config.lport, {'log': false})
console.log(global.config.server + " is Listening...")

global.ssocketio.on('connection', (ssocket) ->
  ssocket.join('server');
  
  # request from client to get a specific file
  ssocket.on('get', (params) ->
    file_path = Common.path.join(global.config.filestore, params.file)
    stream = Common.stream.createStream()
    if Common.fs.existsSync(file_path)
      stat = Common.fs.statSync(file_path)
      Common.stream(csocket).emit('update', stream, {file: params.file, mtime: stat.mtime}) 
      Common.fs.createReadStream(file_path).pipe(stream)
      console.log("Uploading: " + file_path)
    else
      console.log("Requested file does not exist on server") 
      #ssocket.emit('delete',{file:file})
  )
    
  # send a list of files for user to client
  ssocket.on('fetch_list', (params) ->
    path = Common.path.join(config.filestore)
    Common.util.directory(path, (files) ->
      list = {}
      for file, time in files when Common.path.dirname(file) isnt path
        list[file]=time
      ssocket.emit('list', {list:list})
    )
  )

  # client gets disconnected
  ssocket.on('disconnect', () ->
    console.log('server node disconnected')
  )

  # client gets disconnected
  ssocket.on('error', () ->
    console.log('error')
  )
)


################# SERVER - CLIENT COMMUNICATION ##################

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
  
  socket.on('delete', (params) ->
    if (user = Common.auth.valid(params.token))
      path = Common.path.join(global.config.filestore, user, params.file)
      if Common.path.existsSync(path) then Common.fs.unlinkSync(path)
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
