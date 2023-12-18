defmodule Ardea.Service.Http do
  use Agent
  require Logger

  alias Ardea.Service.Http.Endpoint
  @behaviour Ardea.Service

  def validate(opts, name) do
    name = String.to_atom(name)
    base_url = Map.fetch!(opts, "base_url")
    endpoints = Map.fetch!(opts, "endpoints") |> Endpoint.validate()
    valid_opts = [name: name, base_url: base_url, endpoints: endpoints]

    %{
      start: {__MODULE__, :start_link, [valid_opts]},
      id: name
    }
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    Agent.start_link(fn -> opts end, name: name)
  end

  def call(input, name) do
    opts = Agent.get(String.to_existing_atom(name), & &1)
    base_url = Keyword.fetch!(opts, :base_url)

    with {:ok, endpoint} <- Map.fetch(input, "endpoint"),
         {:ok, endpoint} <- Map.fetch(Keyword.fetch!(opts, :endpoints), endpoint),
         {:ok, response} <- Endpoint.make_request(endpoint, base_url, input) do
      to_list(response)
    else
      {:error, error} ->
        Logger.error("Failed http request: #{inspect(error)}")
        []

      :error ->
        Logger.error("Missing or invalid endpoint specification")
        []
    end
  end

  defp to_list(response) when is_list(response), do: response
  defp to_list(response), do: [response]
end
