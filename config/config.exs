import Config

config :logger, :console,
  level: String.to_atom(System.get_env("LOGGER_LEVEL", "debug")),
  truncate: :infinity,
  format: System.get_env("LOGGER_FORMAT", "$date $time [$level] $message") <> "\n",
  metadata: []

config :ardea, Configuration,
  config_dir: System.get_env("CONFIG_DIR", "test_config"),
  config_files: System.get_env("CONFIG_FILES", "config_1.json,config_*.json"),
  service_files: System.get_env("SERVICE_FILES", "service_*.json")
