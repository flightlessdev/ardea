defmodule Ardea.Step.ServiceCall do
  alias Ardea.{Step, Service, Configuration}
  @behaviour Step

  def process(data, %{input: input, data_input: data_input, service: service} = step) do
    # Merge with input last is correct behaviour
    Enum.into(data_input, %{}, fn {input_key, data_key} ->
      {input_key, Map.get(data, data_key)}
    end)
    |> Map.merge(input)
    |> Ardea.Service.call(service)
    |> append(data, step)
  end

  def validate(step) do
    service = Map.get(step, "service")

    if(!Service.exist?(service)) do
      raise Configuration.ConfigError, "Service #{service} does not exist or is invalid"
    end

    input = Map.get(step, "input", %{})
    data_input = Map.get(step, "data_input", %{})
    {append_method, append_path} = validate_append_method(step)

    {:ok,
     %{
       service: service,
       input: input,
       data_input: data_input,
       append_method: append_method,
       append_path: append_path
     }}
  end

  defp validate_append_method(%{"append_method" => "override"}) do
    {:override, nil}
  end

  defp validate_append_method(%{"append_method" => "keep"}) do
    {:keep, nil}
  end

  defp validate_append_method(%{"append_method" => "merge"}) do
    {:merge, nil}
  end

  defp validate_append_method(%{"append_method" => "child", "append_path" => append_path})
       when is_binary(append_path) do
    {:child, append_path}
  end

  defp validate_append_method(%{"append_method" => "children", "append_path" => append_path})
       when is_binary(append_path) do
    {:children, append_path}
  end

  defp validate_append_method(_),
    do: raise(Configuration.ConfigError, "Invalid append method configuration")

  defp append(result, _, %{append_method: :override}), do: result
  defp append(_, data, %{append_method: :keep}), do: [data]
  defp append(result, data, %{append_method: :merge}), do: [data | result]

  defp append(result, data, %{append_method: :children, append_path: path}),
    do: [%{data | path => result}]

  defp append(result, data, %{append_method: :child, append_path: path}),
    do: [%{data | path => Enum.at(result, 0)}]
end
