## luvit-dnode

[![Build Status](https://travis-ci.org/pauldub/luvit-dnode.svg?branch=master)](https://travis-ci.org/pauldub/luvit-dnode)

This a port of [dnode.js](https://github.com/substack/dnode) from [substack](http://substack.net/). dnode is a rpc system allowing clients and servers to communicate with each other.  I decided to write this port for luvit after reading this article: [Top 10 inventions at Browserling](http://www.catonmat.net/blog/top-10-browserling-inventions/). My goal is to port upnode and airport aswell, and maybe seaport too.

It looks like the simple example is working but more work is needed. Right now a good portion of the node.js test suite has been ported, performance will be tested after implementation is correct enough (at least when client functions are accessible from server and directly piping nodes to each other is working). 

After that, I want to cross test both implementations by running the test suite and interleaving node.js and luvit clients and servers.

A simple example server that should run on Heroku and that works fine on dokku is available: [pauldub/dnode-heroku-example](https://github.com/pauldub/dnode-heroku-example).

I am also wondering if luvit can also be used with [OpenResty](http://openresty.org), and allow one to forward urls to dnodes, or something like that.

## Usage

Install deps with `lui`, this will fetch dependencies under `modules/`. Lui is available at [dvv/luvit-lui](https://github.com/dvv/luvit-lui).

### Example Server

```lua
local dnode = require('dnode')

local server = dnode:new({
	hello = function(cb)
		cb("hello world!")
	end
})

server:listen(7070)
```

### Example client

```lua
local dnode = require('dnode')

local client = dnode:new()

client:connect(7070, function(remote, conn)
	remote.hello(function(response)
		print(response)
	end)
end)
```

See the `tests/` directory for more examples.

## Tests

Should write more tests, `bourbon` will eventually run them. For more informations on bourbon, see [racker/luvit-bourbon](https://github.com/racker/luvit-bourbon).

## Current status

Things that work:

- What is currently tested, see `test/` and `test/server` directories.

Things that are probably wrong:

- The scrubber might not be exactly right, it doesn't handle links, indexes starts at 1 due to lua table index. I dont't think callbacks from client -> server are ok, I haven't tested it though.
- The walker might not be right too. I've ported it from the ruby version of dnode and some small parts are missing.
- There is a small logger library, this is just actually used for debugging purposes and helping me understanding how things work. Actually they used to be print(dump(...)) statements the logger main purpose is toggling them.
- ~~The arguments for `dnode:listen` and `dnode:connect` are not yet defined and atm sucks badly.~~ `dnode:listen` and `dnode:connect` now work more or less like the node.js version and those arguments orders should be supported: `port`, `port, cb`, `port, host, cb` or `{ port = p, host = h }, cb`. TODO: Test dnode initialization arguments.
- Bits of everything else.

Things that don't work:

- No support for links (yet).
- Server doesn't see client functions.
- Cannot pipe dnodes to each other yet (using `dnode:new`), I don't know exactly why but it might be due to missing parts or messages going to the `handling_queue` and staying there.

