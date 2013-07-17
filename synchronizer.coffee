Common = require './common'

Syncronizer = (socket) ->
  
  create: (file, stat, basepath) ->
    update_file(file, socket, stat.mtime, basepath)
    console.log("Create " + file)

  update: (file, stat, basepath) ->
    update_file(file, socket, stat.mtime, basepath)

  remove: (file, stat, basepath) ->
    console.log("Delete" + file)
    
  update_since: (timestamp, directory) ->
    files_updated_since(timestamp, directory, socket)

module.exports = Syncronizer

# file: relative path of file
# basepath: path where file is stored
update_file = (file, socket, mtime, basepath) ->
  absfile = Common.path.join(basepath,file)
  
  stream = Common.stream.createStream()
  Common.stream(socket).emit('update', stream, {name: file, token: global.auth_token})
  Common.fs.createReadStream(absfile).pipe(stream)
  global.config.last_updated = mtime
  Common.util.save_config(global.config)
  console.log(absfile)  
# timestamps being stored in GMT
  
files_updated_since = (timestamp, directory,socket) ->
  walker = Common.walk.walk(directory,{followLinks: false})
  timestamp = new Date(timestamp)
  console.log(timestamp)
  walker.on('file', (root,stat,next)->
    update_file(stat.name, socket, stat.mtime, directory) if stat.mtime > timestamp
    next()
  )
