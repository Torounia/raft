import Config

config :logger, :console,
  backends: [:console],
  level: :debug,
  format: {Raft.LogFormatter, :format},
  metadata: [:node]

# metadata: [:node, :mfa, :pid, :registered_name]
