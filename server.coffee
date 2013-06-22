# load configuration file
config = require('nconf')
config.use('file', { file: './server-config.json' })
config.load()

# http server for updates
app = require('express')()
server = require('http').Server(app)

app.get('/', (req, res) -> 
  res.send('Hello world!')
)

# start server
server.listen(config.get("port"))
console.log("Listening...")

# persistent connection for events
io = require('socket.io')(server)
io.on('connect', ()->
  io.emit('hello')
  console.log('connected')
)
