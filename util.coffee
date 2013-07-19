# Helper functions that don't go elsewhere

mkdirp = require('mkdirp')
fs = require 'fs'

# Creates a path if it does not exist already
exports.ensure_folder_exists = (dir) ->
  mkdirp(dir,(err)->
    if err then console.log(err)
  )

# Replaces ~ in path with home directory
exports.expand = (directory) ->
  directory.replace(/^~/,process.env['HOME'])

# Saves configuration to disk
exports.save_config = (config) ->
  data = JSON.stringify(config,null,2)
  
  # The config file that needs to be overwritten is just client. Not saving timestamp on server side
  fs.writeFile('./config/client.json', data, (err) ->
    if err
      console.log('There has been an error saving your configuration data.' + err.message)
    else
      console.log('Configuration saved successfully.')
  )

# Callsback with a list of files in `path` with their last modified times
exports.directory = (path, callback) =>
  path = Common.util.expand(path)
  files = {}
  walker = Common.walk.walk(path,{followLinks: false})
  
  walker.on('file', (root,stat,next)->
    dir = Common.path.relative(path, root)
    file = Common.path.join(dir,stat.name)
    files[file] = stat.mtime
    next()
  )
  
  walker.on('end', () =>
    callback files
  )