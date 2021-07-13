import Config

config :logger, :console,
  backends: [:console],
  level: :debug,
  format: "$time [$level][$metadata]$message \n",
  metadata: [:mfa, :pid, :registered_name]
