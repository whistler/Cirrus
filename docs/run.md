Install/Run
===========
Copy the complete directory on to your system. Install Node.js and CoffeeScript.
A Ubuntu installation file for these two is included in this folder.

In the program directory, run:
    
    npm install

Depending on whether this is the client or server machine. Open and configure `config/client.json` on the client and `config/server.json` on the server.

To run the server type:
    
    coffee server.coffee

To run the client type:
    
    coffee client.coffee

More information on configuration can be found in info.pdf