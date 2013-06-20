# load configuration file
config = require('nconf')
config.use('file', { file: './config.json' });
config.load();

# start watching directory
watcher = require('./client/watcher')(config.get("directory"))

console.log("Watching " + config.get("directory") + "...")