config = require('nconf')

# load configuration file
config.use('file', { file: './config.json' });
config.load();


console.log("Watching " + config.get("directory") + "...")