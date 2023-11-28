import Config

config :ardea, Configuration,
  config_dir: System.get_env("CONFIG_DIR", "test_config"),
  config_files: System.get_env("CONFIG_FILES", "config_1.json,config_*.json")
