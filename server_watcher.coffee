Common = require './common'
watcher = require('watch')

# Watches file in 'directory' and notifies 'synchronizer' of
# any changes to files  
class Watcher

  # synchronizer - server synchronizer object
  # directory - base filestore directory, should be global.config.filestore
  # socket - the socket for this particular user
  # user - name of the user
  constructor: (synchronizer, directory, socket, user) ->

    @directory = Common.path.normalize(directory)
    @file_list_path = Common.path.join(directory, user+".json")
    @user_directory = Common.path.join(directory, user)
    @file_list = null
    Common.util.ensure_file_exists(@file_list_path)
    console.log("file_list_path: " + @file_list_path)
    @file_list = require ("./" + @file_list_path)
    @socket = socket
    @user = user
    
    watcher.createMonitor(@user_directory, (monitor) =>
      monitor.on("created", (file, stat) =>
        synchronizer.send(@relative_path(file), @user_directory, stat.mtime, 0, @socket)
      )
      monitor.on("changed", (file, curr, prev) =>
        if !@file_list[@relative_path(file)] || curr.mtime > new Date(@file_list[file])
          synchronizer.send(@relative_path(file), @user_directory, curr.mtime, prev.mtime, @socket)
      )
      monitor.on("removed", (file, stat) ->
        synchronizer.destroy(@relative_path(file), @socket)
        set_timestamp(@relative_path(file), "deleted")
      )
    )

    console.log("Watching " + @directory + "...")
  
  # returns path of file relative to 'directory'
  relative_path: (file) ->
    return Common.path.relative(@user_directory, file)
  
  set_timestamp: (file, timestamp) ->
    @file_list[file] = timestamp
    Common.util.save_file(@file_list_path, @file_list)
    console.log file + ": " + timestamp
  
  get_timestamp: (file) ->
    @file_list[file]

module.exports = Watcher
