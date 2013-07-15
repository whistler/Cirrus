# DB LIKE CLIENT

# load configuration file
try
  config = require('./config/client')

  # persistent connection
  socket = require('socket.io-client')("http://" + config.host + ":" + config.port)
  global.auth_token = ""
  
  socket.on('connect', () ->
  
    console.log('connected')
    socket.emit('auth', {username: config.username, password: config.password})
  
    socket.on('disconnect', ()->
      console.log('Disconnected :(')
    )
    socket.on('error', (err)->
      console.log(err)
      console.log("TODO: Try to reconnect after timeout")
    )
    socket.on('unauthorized', ()->
      console.log("Unable to log in")
      process.exit(1)
    )
    socket.on('token', (tok)->
      global.auth_token = tok
      console.log(tok)
    )
  )

  # synchronizer
  synchronizer = require('./synchronizer')(socket)

  # start watching directory
  watcher = require('./watcher')(synchronizer)
catch e
  console.trace(e)
  
