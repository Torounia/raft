import Config

config :logger,
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

# metadata: [:node, :mfa, :pid, :registered_name]
