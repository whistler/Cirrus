config = require('./config/client')
fs = require('fs')
path = require('path')
iostream = require('socket.io-stream')

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


update_file = (file,socket) ->
  watchdir = path.normalize(config.directory)
  absfile = path.join(watchdir,file)

  stream = iostream.createStream()
  iostream(socket).emit('update', stream, {name: file, token: global.auth_token})
  fs.createReadStream(absfile).pipe(stream)