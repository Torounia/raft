import Config

config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :debug]
  ],
  backends: [:console, {LoggerFileBackend, :debug_log}],
  format: {Raft.LogFormatter, :format},
  metadata: [:node]

config :logger, :console, level: :info

debug_filename = Atom.to_string(Node.self()) <> "_debug.log"

config :logger, :debug_log,
  path: debug_filename,
  level: :debug,
  format: {Raft.LogFormatter, :format},
  metadata: [:node, :mfa]

config :raft,
  peers3: [
    :"nerves-9398@nerves-9398.local",
    :"nerves-9ef5@nerves-9ef5.local",
    :"nerves-9c9e@nerves-9c9e.local"
  ],
  peers5: [
    :"nerves-9398@nerves-9398.local",
    :"nerves-2be4@nerves-2be4.local",
    :"nerves-9ef5@nerves-9ef5.local",
    :"nerves-9c9e@nerves-9c9e.local",
    :"nerves-fa27@nerves-fa27.local"
  ],
  peers7: [
    :"nerves-9398@nerves-9398.local",
    :"nerves-2be4@nerves-2be4.local",
    :"nerves-9ef5@nerves-9ef5.local",
    :"nerves-9c9e@nerves-9c9e.local",
    :"nerves-fa27@nerves-fa27.local",
    :"nerves-1152@nerves-1152.local",
    :"nerves-4e22@nerves-4e22.local"
  ]
