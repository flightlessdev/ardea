import Config

if config_env() == :prod do
  config :logger, :console,
    level: String.to_atom(System.get_env("LOGGER_LEVEL", "info")),
    truncate: :infinity,
    format: System.get_env("LOGGER_FORMAT", "$date $time [$level] $message") <> "\n",
    metadata: []
end
