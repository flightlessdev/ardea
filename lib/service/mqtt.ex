defmodule Ardea.Service.Mqtt do
  require Logger
  @behaviour Ardea.Service

  def validate(opts, name) do
    # TODO: more opts from ExMQTT

    opts = [
      host: read_host(opts),
      port: read_port(opts),
      username: read_username(opts),
      password: read_password(opts),
      client_id: Map.get(opts, "client_id", name),
      # Conn name is mapped to genserver name thus need to be atom
      conn_name: String.to_atom(name)
    ]

    %{
      start: {ExMQTT, :start_link, [opts]},
      id: name
    }
  end

  defp read_host(opts) do
    Map.fetch!(opts, "host")
  end

  defp read_port(opts) do
    Map.fetch!(opts, "port")
  end

  defp read_username(opts) do
    {:value, value} = Ardea.Common.Secret.read(Map.get(opts, "username"))
    value
  end

  defp read_password(opts) do
    {:value, value} = Ardea.Common.Secret.read(Map.get(opts, "password"))
    value
  end

  def call(%{"topic" => topic, "message" => message} = input, name) do
    qos = Map.get(input, "qos", 1)
    ExMQTT.publish(String.to_existing_atom(name), message, topic, qos)
    []
  end

  def call(_data, _) do
    Logger.error("Invalid mqtt publish call. Missing topic and/or message")
    []
  end
end
