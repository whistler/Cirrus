# Helper functions that don't go elsewhere

util = require './util'
mkdirp = require 'mkdirp'
fs = require 'fs'
walk = require 'walk'
path = require 'path'
touch = require 'touch'

# Creates a path if it does not exist already
exports.ensure_folder_exists = (dir) ->
  mkdirp(dir,(err)->
    if err then console.log(err)
  )

# 
exports.ensure_file_exists = (path) ->
  fs.exists(path, (exists) ->
    console.log(exists)
    if !exists then exports.save_file(path, {})
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
exports.directory = (dir_path, callback) =>
  dir_path = util.expand(dir_path)
  files = {}
  walker = walk.walk(dir_path,{followLinks: false})
  
  walker.on('file', (root,stat,next) ->
    dir = path.relative(dir_path, root)
    file = path.join(dir,stat.name)
    files[file] = stat.mtime
    next()
  )
  
  walker.on('end', () =>
    callback files
  )
  
  
exports.save_file = (file, data) ->
  console.log(data)
  data = JSON.stringify(data,null,2)
  console.log(data)
  fs.writeFile(file, data, (err) ->
    if err
      console.log('Error writing ' + file + ": " + err.message)
  )