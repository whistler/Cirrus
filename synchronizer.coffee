fs = require('fs')
path = require('path')
# load configuration file
config = require('./config/client')

Syncronizer = (io) ->
  
  create: (file) ->
    #PUT
    console.log("Create " + file)

  update: (file) ->
    #POST
    update_file(file,io)

  remove: (file) ->
    #DELETE
    console.log("Delete" + file)

module.exports = Syncronizer


update_file = (file,io) ->
  watchdir = path.normalize(config.directory)
  absfile = path.join(watchdir,file)
  ss = require('socket.io-stream')

  stream = ss.createStream()

  ss(io).emit('update', stream, {name: file})
  fs.createReadStream(absfile).pipe(stream)