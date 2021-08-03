import Config

config :logger,
  backends: [:console, {LoggerFileBackend, :error_log}],
  format: {Raft.LogFormatter, :format},
  metadata: [:node, :mfa]

config :logger, :console, level: :info

debug_filename = Atom.to_string(Node.self()) <> "_debug.log"

config :logger, :error_log,
  path: debug_filename,
  level: :debug

# metadata: [:node, :mfa, :pid, :registered_name]
