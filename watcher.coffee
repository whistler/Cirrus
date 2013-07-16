config = require './config/client'
path = require 'path'
directory = config.directory.replace(/^~/,process.env['HOME'])
directory = path.normalize(directory)
console.log directory

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

  console.log("Watching " + config.directory + "...")

module.exports = Watcher

relative_path = (file) ->
  return path.relative(directory, file)
