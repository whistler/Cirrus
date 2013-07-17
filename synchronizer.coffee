config = require('./config/client')
fs = require('fs')
path = require('path')
util = require('./util')
iostream = require('socket.io-stream')
walk = require('walk')

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
    
  update_since: () ->
    directory = util.expand(config.directory)
    files_updated_since(config.last_updated,directory, io)

module.exports = Syncronizer


update_file = (file,socket, mtime) ->
  watchdir = util.expand(config.directory)
  absfile = path.join(watchdir,file)
  
  stream = iostream.createStream()
  iostream(socket).emit('update', stream, {name: file, token: global.auth_token})
  fs.createReadStream(absfile).pipe(stream)
  config.last_updated = mtime
  util.save_config(config)
  console.log(absfile)  
# timestamps being stored in GMT

server_files_updated_since = (timestamp,user, socket) ->
  directory = path.join(config.filestore,user)
  files_updated_since(timestamp,directory,socket)
  
files_updated_since = (timestamp,directory,socket) ->
  walker = walk.walk(directory,{followLinks: false})
  timestamp = new Date(timestamp)
  console.log(timestamp)
  walker.on('file', (root,stat,next)->
    update_file(stat.name, socket, stat.mtime) if stat.mtime > timestamp
    next()
  )
