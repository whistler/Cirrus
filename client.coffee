# Cirrus Client Program
global.app = "client"
global.config = require('./config/client')
global.serv = global.config.servers[global.config.current_server]
Common = require './common'
socket = null

client = require('socket.io-client')
synchronizer = require('./client_synchronizer') # sends updates to server
watcher = require('./watcher')

# start watching directory
directory = Common.util.expand(global.config.directory)
state_path = "./" + global.app + "-files.json"
watcher.start(synchronizer, directory, state_path)
synchronizer.set_watcher(watcher)

start_client = () ->
  # Connect to server
  options = {'transports':['websocket'], 'connect timeout':5000, 'force new connection': true}
  console.log('connecting to server: ' + global.config.current_server)
  socket = client.connect("http://" + global.serv.host + ":" + global.serv.port, options)
  
  synchronizer.set_socket(socket)

  socket.on('connect', () ->
    console.log('Connected to Server! ' + global.serv.server)
    socket.emit('auth', {username: global.config.username, password: global.config.password})

    # recieve file updates from client
    Common.stream(socket).on('update', (stream, params) ->
      synchronizer.get(stream, params, socket)
    )
  )

  # reconnect on disconnect or error
  socket.on('disconnect', () ->
    console.log('Server Disconnected')
    next_server()
  )
  socket.on('error', (err) ->
    next_server()
    console.log("Socket Error")
  )

  # Send file that server requests
  socket.on('get', (params) ->
    file_path = Common.path.join(Common.util.expand(global.config.directory), params.file)
    stream = Common.stream.createStream()
    if Common.fs.existsSync(file_path)
      stat = Common.fs.statSync(file_path)
      Common.stream(socket).emit('update', stream, {file: params.file, token: global.auth_token, time: stat.mtime}) 
      Common.fs.createReadStream(file_path).pipe(stream)
      console.log("Uploading Requested File: " + file_path)
  )

  # server reports file recieved successfully
  socket.on('update_success', (params)->
    watcher.set_timestamp(params.file, params.time)
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
    synchronizer.sync(params.list, watcher, socket)
  )

  # delete the file removed on the server
  socket.on('delete', (params) ->
    path = Common.path.join(Common.util.expand(global.config.directory), params.file)
    console.log("delete " + path)
    if Common.fs.existsSync(path) then Common.fs.unlinkSync(path)
  )

  # display message from server
  socket.on('message', (params)->
    console.log (params)
  )

  # Event triggered on successful authentication, send and recieve updates during downtime
  socket.on('authenticated', (token) ->
    global.auth_token = token
    socket.emit('fetch_list', {token: token})
    console.log("Successfully logged in!")
  )

start_client()

# Connect to next server (used when disconnected or unable to connect)
next_server = () ->
  if !socket.connected
    socket.removeAllListeners() if socket
    global.config.current_server = (global.config.current_server + 1) % global.config.servers.length
    global.serv = global.config.servers[global.config.current_server]
    setTimeout(start_client, 5000);
    Common.util.save_config(global.config)
