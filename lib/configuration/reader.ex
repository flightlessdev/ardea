defmodule Ardea.Configuration.Reader do
  alias Ardea.{Job, Service}
  alias Ardea.Configuration.ConfigError
  @steps_array "steps"

  def read_services do
    opts = Application.fetch_env!(:ardea, Configuration)
    config_dir = Keyword.fetch!(opts, :config_dir)

    get_json_files(opts, config_dir, :service_files)
    |> Stream.flat_map(&Service.validate/1)
    |> Enum.to_list()
    |> Enum.reduce(%{}, fn %Ardea.Service{name: name} = service, acc ->
      add_unique_component(name, service, acc, "service")
    end)
    |> Ardea.Service.register_services()
    |> Enum.reject(&(!is_map(&1)))
  end

  def read_jobs do
    opts = Application.fetch_env!(:ardea, Configuration)
    config_dir = Keyword.fetch!(opts, :config_dir)

    get_json_files(opts, config_dir, :config_files)
    |> Stream.map(&resolve_step_references(&1, config_dir))
    |> Stream.map(&Job.validate/1)
    |> Enum.to_list()
    |> Enum.reduce(%{}, fn %{name: name} = job, acc ->
      add_unique_component(name, job, acc, "job")
    end)
  end

  defp get_json_files(opts, config_dir, key) do
    Keyword.fetch!(opts, key)
    |> String.split(",")
    |> Enum.map(fn x -> "#{config_dir}/#{x}" end)
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.uniq()
    |> Stream.map(&File.read!/1)
    |> Stream.map(&Jason.decode!/1)
  end

  defp add_unique_component(name, data, map, item) do
    if Map.has_key?(map, name) do
      raise ConfigError, "Duplicate #{item} name '#{name}'"
    else
      Map.put(map, name, data)
    end
  end

  defp resolve_step_references(config, config_dir) do
    Map.put(config, @steps_array, resolve_references(config, config_dir))
  end

  defp resolve_references(config, config_dir) when is_map(config) do
    Map.fetch!(config, @steps_array) |> resolve_references(config_dir)
  end

  defp resolve_references(config, config_dir) when is_list(config) do
    Enum.flat_map(config, fn x -> resolve_reference(x, config_dir) end)
  end

  defp resolve_references(_config, _config_dir), do: raise(ConfigError, "Invalid steps reference")

  defp resolve_reference(ref, config_dir) when is_binary(ref) do
    File.read!("#{config_dir}/#{ref}") |> Jason.decode!() |> resolve_references(config_dir)
  end

  defp resolve_reference(ref, _config_dir) when is_map(ref), do: [ref]

  defp resolve_reference(_ref, _config_dir),
    do: raise(ConfigError, "Invalid step format")
end
