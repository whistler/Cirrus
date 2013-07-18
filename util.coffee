# Helper functions that don't go elsewhere

mkdirp = require('mkdirp')
fs = require('fs')

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
  data = JSON.stringify(config,null,2);
  app = global.app
  
  # The config file that needs to be overwritten is just client. Not saving timestamp on server side
  fs.writeFile('./config/client.json', data, (err) ->
    if err
      console.log('There has been an error saving your configuration data.')
      console.log(err.message)
      return
      console.log('Configuration saved successfully.')
  )
