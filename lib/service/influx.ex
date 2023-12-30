defmodule Ardea.Service.Influx do
  require Logger
  alias Ardea.Configuration.ConfigError
  alias Ardea.Service

  use Instream.Connection, otp_app: :ardea, config: [init: {__MODULE__, :init_instream}]

  @behaviour Ardea.Service

  def init_instream(_) do
    # Required by dynamic reading of
    # TODO: check connection
    :ok
  end

  @impl Service
  def validate(opts, name) do
    if Application.get_env(:ardea, __MODULE__) != nil,
      do: raise(ConfigError, "Only support one influxdb service due to library limitation")

    config =
      Keyword.merge(config(),
        otp_app: :ardea,
        name: name,
        host: Map.fetch!(opts, "host"),
        port: Map.fetch!(opts, "port"),
        auth: auth(Map.fetch!(opts, "auth_method"), opts),
        version: :v2
        # TODO: Support all options, including version: :v1
      )

    Application.put_env(:ardea, __MODULE__, config)
    child_spec(nil)
  end

  defp auth("token", opts), do: [method: :token, token: read_token(opts)]

  defp auth("basic", opts),
    do: [method: :basic, username: read_username(opts), password: read_password(opts)]

  defp auth(method, _), do: raise(ConfigError, "Invalid auth method #{method}")

  defp read_username(opts) do
    {:value, value} = Ardea.Common.Secret.read(Map.get(opts, "username"))
    value
  end

  defp read_password(opts) do
    {:value, value} = Ardea.Common.Secret.read(Map.get(opts, "password"))
    value
  end

  defp read_token(opts) do
    {:value, value} = Ardea.Common.Secret.read(Map.get(opts, "token"))
    value
  end

  @impl Service
  def call(input, _name) do
    # TODO: implement read
    measurement = Map.get(input, "measurement")
    tags = Map.get(input, "tags", [])
    fields = Map.get(input, "fields", [])

    with {:ok, point} <- get_point(measurement, tags, fields, input),
         {:ok, org} <- get_org(input),
         {:ok, bucket} <- get_bucket(input),
         :ok <- write(point, bucket: bucket, org: org) do
      []
    else
      {:error, error} ->
        Logger.error("Failed to write to influxdb due to: #{inspect(error)}")
        []

      %{code: code, message: message} ->
        Logger.error("Error response from influx. Code: #{code}, message: #{message}")
    end
  end

  defp get_org(input) do
    case Map.fetch(input, "org") do
      {:ok, _org} = res -> res
      :error -> {:error, "Missing org"}
    end
  end

  defp get_bucket(input) do
    case Map.fetch(input, "bucket") do
      {:ok, _bucket} = res -> res
      :error -> {:error, "Missing bucket"}
    end
  end

  defp get_point(nil, _, _, _), do: {:error, "Missing measurement"}

  defp get_point(_, tags, _, _) when length(tags) < 1 or not is_list(tags),
    do: {:error, "Require at least one tag"}

  defp get_point(_, _, fields, _) when length(fields) < 1 or not is_list(fields),
    do: {:error, "Require at least one field"}

  defp get_point(measurement, tags, fields, input) do
    with {:ok, tags_data} = get_tags_or_field_data(tags, input),
         {:ok, fields_data} = get_tags_or_field_data(fields, input),
         :ok <- require_tags(tags_data) do
      {:ok, %{measurement: measurement, tags: tags_data, fields: fields_data}}
    else
      error -> error
    end
  end

  defp get_tags_or_field_data(keys, input) do
    {:ok, Enum.reduce(keys, %{}, &Map.put(&2, &1, Map.get(input, &1)))}
  end

  defp require_tags(tags) do
    case Enum.filter(tags, fn {_key, value} -> is_nil(value) end) do
      [] -> :ok
      tags -> {:error, "Tags are nil: #{inspect(tags)}"}
    end
  end
end
