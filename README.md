# Raft

##TODO: 
Add description
check for naming convention
check for error catches

Election timer timeouts while on leader state. Set a clause catcher inside candidate state, to exit the function or fix within the timer service. THis seems to be ok. More investigation to understand why cancelling timer 2 when only 1 timer started.

There seems to be a fault with election timer reset while in follower state. Election timeouts on followers and they start election. To check -  fixed. Raft is stable

28/07: Fixed election timer and heartbeat timer. Added log to file and log to console. Next: improve info logging and build a client to send cmds to the logger. Start building the testing functions
        

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `raft` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:raft, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/raft](https://hexdocs.pm/raft).

