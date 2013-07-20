# Cirrus Client
global.app = "client"
global.config = require('./config/client')
global.serv = global.config.servers[global.config.current_server]
Common = require './common'

# Connect to server
client = require('socket.io-client')
socket = client.connect("http://" + global.serv.host + ":" + global.serv.port, {'transports':['websocket']})
synchronizer = require('./client_synchronizer') # sends updates to server
synchronizer.set_socket(socket)

# start watching directory
directory = Common.util.expand(global.config.directory)
watcher = require('./watcher')
watcher.start(synchronizer, directory)

socket.on('connect', () ->
  console.log('Connected to Server! ' + global.serv.server)
  socket.emit('auth', {username: global.config.username, password: global.config.password})
  
  # recieve file updates from client
  Common.stream(socket).on('update', (stream, params) ->
    filename = Common.path.join(Common.util.expand(global.config.directory), params.name)
    path = Common.path.dirname(filename)
    Common.util.ensure_folder_exists(path)
    stream.on('close', () ->
      Common.fs.open(filename, 'a', (err, fd) ->
        watcher.updated(filename, params.mtime)
        mtime = new Date(params.mtime)
        Common.fs.futimesSync(fd, mtime, mtime)
      )
    )
    stream.pipe(Common.fs.createWriteStream(filename))
    console.log('Downloading ' + params.name)
  )
)

sync = (remote, local, socket) ->
  console.log('Sync')
  console.log(remote)
  for file, mtime of remote
    if local[file]==undefined || new Date(mtime) > new Date(local[file])
      socket.emit('get', {file: file, token: global.auth_token})

next_server = () ->
  if ++global.config.current_server==global.config.servers.length
    global.config.current_server = 0
  Common.util.save_config(global.config)

socket.on('disconnect', () ->
  console.log('Server Disconnected')
  next_server()
)

socket.on('error', (err) ->
  console.log(err)
  console.log("TODO: Try to reconnect after timeout")
  next_server()
)

# Send file that server requests
socket.on('get', (params) ->
  file_path = Common.path.join(Common.util.expand(global.config.directory), params.file)
  stream = Common.stream.createStream()
  stat = Common.fs.statSync(file_path)
  Common.stream(socket).emit('update', stream, {name: params.file, token: global.auth_token, mtime: stat.mtime}) 
  Common.fs.createReadStream(file_path).pipe(stream)
  console.log("Uploading: " + file_path)
)

# Event triggered if username/password or token provided was invalid
socket.on('unauthorized', () ->
  console.log("Unable to log in")
  process.exit(1)
)

# sends list of files in directory to sever
socket.on('fetch_list', (params) ->
  console.log('Sending list to server')
  path = config.directory
  Common.util.directory(path, (files) ->
    socket.emit('list', {list:files, token: global.auth_token})
  )
)

# receive updated list of files on client with their timestamps
socket.on('list', (params) ->
  console.log('recieved list from server')
  path = Common.util.expand(config.directory)
  Common.util.directory(path, (files) ->
    sync(params.list, files, socket)
  )
)

# Event triggered on successful authentication, send and recieve updates during downtime
socket.on('authenticated', (token) ->
  global.auth_token = token
  socket.emit('fetch_list', {token: token})
  console.log("Successfully logged in!")
  #synchronizer.update_since(global.config.last_updated, Common.util.expand(global.config.directory))
  #socket.emit('fetch_updates', {'since': global.config.last_updated, 'token' : global.auth_token})
  #socket.emit('get', {'token':token, file:'hi'})
)
