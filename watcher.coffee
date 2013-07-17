path = require 'path'
util = require './util'

directory = util.expand(global.config.directory)
directory = path.normalize(directory)

Watcher = (synchronizer) ->

  try
    watcher = require('watch')
    watcher.createMonitor(directory, (monitor) ->

      monitor.on("created", (file, stat) ->
        console.log(file + " created")
        synchronizer.create(relative_path(file))
      )
      monitor.on("changed", (file, curr, prev) ->
        console.log(file + " changed")
        synchronizer.update(relative_path(file))
      )
      monitor.on("removed", (file, stat) ->
        console.log(file + " removed")
        synchronizer.remove(relative_path(file))
      )
    )
  catch
    console.log("Error reading directory: " + config.directory + 
      ". Make sure it exists.")

  console.log("Watching " + global.config.directory + "...")

module.exports = Watcher

relative_path = (file) ->
  return path.relative(directory, file)
