import Config

config :logger,
  compile_time_purge_level: :warn,
  backends: [:console, {LoggerFileBackend, :debug_log}],
  format: {Raft.LogFormatter, :format},
  metadata: [:node]

config :logger, :console, level: :info, compile_time_purge_level: :warn

debug_filename = Atom.to_string(Node.self()) <> "_debug.log"

config :logger, :debug_log,
  compile_time_purge_level: :warn,
  path: debug_filename,
  max_no_bytes: 5_000_000,
  level: :warn,
  format: {Raft.LogFormatter, :format},
  metadata: [:node, :mfa]

# metadata: [:node, :mfa, :pid, :registered_name]

TODO
# compile_time_purge_matching: [
#   [level_lower_than: :info]
# ]
