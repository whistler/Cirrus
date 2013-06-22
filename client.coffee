# load configuration file
config = require('nconf')
config.use('file', { file: './config.json' });
config.load();

# start watching directory
watcher = require('./client/watcher')(config.get("directory"))
console.log("Watching " + config.get("directory") + "...")


socket = require('socket.io-client')(config.get('host'))

client = require('http')
client.get(config.get('host'), (res)->
  output = ''
  res.on('data', (data)->
    output += data
  )
  res.on('end', ()->
    console.log(output)
  )
)

socket.on('connect', () ->
  console.log('connected')
  socket.on('hello', (data) ->
    console.log('hello')
  )
  socket.on('disconnect', ()->
    console.log('Disconnected :(')
  )
)