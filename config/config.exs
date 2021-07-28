import Config

config :logger,
  backends: [:console, {LoggerFileBackend, :error_log}],
  format: {Raft.LogFormatter, :format},
  metadata: [:node]

config :logger, :console, level: :info

config :logger, :error_log,
  path: "debug.log",
  level: :debug

# metadata: [:node, :mfa, :pid, :registered_name]
