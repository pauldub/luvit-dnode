## Luvit dnode

This a port of dnode.js from substack. Dnode is a rpc protocol allowing client and servers to communicate with each other.

It looks like the simple example is working but more work is needed.

Things that are probably wrong:

	- the scrubber might not be exactly right, it doesn't handle links, indexes starts at 1 due to lua table index. I dont't think callbacks from client -> server are ok, I haven't tested it though.
	- the walker might be right too. I've ported it from the ruby version of dnode and some small parts are missing.
	- There is a small logger library, this is just actually inteded for debugging purposes and helping me understanding how things work. Actually they were print(dump(...)) statements the logger main purpose is toggling them.
	- bits of everything else.

Things that don't work:

	- no support for links (yet).

## Usage

Install deps `lui` (see lui-url TODO: add lui-url)

```
Hello client
```

```
Hello server
```

See the `examples/` directory for a simple example.

## Tests

Should write more tests, `bourbon` will eventually run them. TODO: Link to bourbon 

