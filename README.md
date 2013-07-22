Cirrus
======

Cirrus is a file backup and sync service programmed in node.js that can be used
to create your own file cloud. [Why not to use Dropbox?](http://dumpdropbox.com/). Check out the docs folder for more information on how to run Cirrus.

Features
--------

- Client has a folder that syncs with the server
  - Any changes in local files are automatically updated on server
  - Any changes on server automatically sync with local folder
- User can have multiple clients that sync with the server
- If two servers crash, service will still be available
- Client authenticates with the server before sync
- More than one clients are able to update a file
- If a server crashes it recovers without a problem

Future updates
--------------
- Updates should be incremental
- If two clients are on a local network, they should be able to sync locally
- GUI Client


Design
------

### Sync Algorithm ###

- Persistent Websocket connection to the server
- Async events to clients for each file creation, change and deletion
- On connect send list of all files with their timestamps and let the other end pull the ones required
- Last sync time, modified time on client and server is used to figure out whether to replace or create a different version


### Incremental Updates ###

#### Possible Solution ####
Use rsync algorithm: [rsync-node](https://github.com/ttezel/anchor) rync
over http using node
[Rsync Algorithm](http://www.samba.org/~tridge/phd_thesis.pdf)

#### Another Possible Solution ####
- Keep diffs for last n changes on for every user on server
- Send diffs patches to client instead of complete file
- Do the same on client

### Server Setup Script ###
- Create EC2 instances and setup all required software

### Server database ###
- Json file with list of users

### How sync between servers ###
- P2P communication, two sockets opened to each node, one for recieving updates another to send updates. This simplifies discovery of nodes.
- Async syncronization similar to client server
- Double writes create different versions 

### Configuration file ###
- Create a json config file for client and server

### Authentication ###
- Username, password to login, then a token till the rest of the session
- No auth between nodes yet