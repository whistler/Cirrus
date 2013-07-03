# load configuration file
config = require('./config/server')

# http server for updates
express = require('express')
app = express.createServer()
server = require('http').Server(app)

app.use(express.bodyParser());

app.get('/', (req, res) -> 
  res.send('Hello world!')
)

app.post('/*', (req, res) ->
  debugger;
  console.log("Got:" + JSON.stringify(req.params))
)

# start server
server.listen(config.port)
console.log("Listening...")

# persistent connection for events
io = require('socket.io')(server)
io.on('connect', ()->
  io.emit('hello')
  console.log('connected')
)
