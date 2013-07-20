Common = require './common'

watcher = require('watch')
debug = false
files = {}
dir = ""
# Watches file in 'directory' and notifies 'synchronizer' of
# any changes to files  
exports.start = (synchronizer, directory) ->
  try
    directory = Common.path.normalize(directory)
    dir = directory
    watcher.createMonitor(directory, (monitor) ->

      monitor.on("created", (file, stat) ->
        console.log(file + " created") if debug
        synchronizer.create(relative_path(file), stat, directory)
      )
      monitor.on("changed", (file, curr, prev) ->
        if !files[file] || curr.mtime > files[file]
          console.log(file + " changed " + curr.mtime) if debug
          synchronizer.update(relative_path(file), curr, directory)
      )
      monitor.on("removed", (file, stat) ->
        console.log(file + " removed") if debug
        synchronizer.remove(relative_path(file), stat, directory)
      )
    )
  catch
    console.log("Error reading directory: " + global.config.directory + 
      ". Make sure it exists.")

  console.log("Watching " + directory + "...")
  
  
exports.updated = (file, timestamp) ->
  files[file] = timestamp
  
# returns path of file relative to 'directory'
relative_path = (file) ->
  return Common.path.relative(dir, file)
