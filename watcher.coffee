Common = require './common'

watcher = require('watch')
debug = false
files = {}
# Watches file in 'directory' and notifies 'synchronizer' of
# any changes to files  
exports.start = (synchronizer, directory, files_path) ->

  directory = Common.path.normalize(directory)
  Common.util.ensure_file_exists(files_path)
  files = require (files_path)
  watcher.createMonitor(directory, (monitor) ->

    monitor.on("created", (file, stat) ->
      console.log(file + " created") if debug
      synchronizer.send(relative_path(file), stat, directory)
      updated(file, stat.mtime)
    )
    monitor.on("changed", (file, curr, prev) ->
      if !files[file] || curr.mtime > files[file]
        console.log(file + " changed " + curr.mtime) if debug
        synchronizer.send(relative_path(file), curr, directory)
    )
    monitor.on("removed", (file, stat) ->
      console.log(file + " removed") if debug
      synchronizer.destroy(relative_path(file), stat, directory)
      updated(file, "deleted")
    )
  )

  console.log("Watching " + directory + "...")
  
  # saves state to disk ever minute
  setInterval(() ->
    Common.util.save_file(files_path, files)
  ,global.config.save_state
  )
  
  
updated = (file, timestamp) ->
  files[file] = timestamp
  
# returns path of file relative to 'directory'
relative_path = (file) ->
  return Common.path.relative(dir, file)
