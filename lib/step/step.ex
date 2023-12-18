defmodule Ardea.Step do
  require Logger
  @callback validate(step :: map()) :: {:ok, step :: map()} | {:error, reason :: term}
  @callback process(data :: map(), step :: map()) :: data :: [map()]

  def step(%{type: type} = step, data) do
    # Module should always be valid due to validation
    module = String.downcase(type) |> Macro.camelize() |> String.to_existing_atom()
    step_module = Module.concat(Ardea.Step, module)
    log_step_start(step)
    log_input_size(data)
    Enum.flat_map(data, &apply(step_module, :process, [&1, step]))
  end

  def validate(%{"type" => type} = step) do
    name = Map.get(step, "name")

    with {:ok, step_module} <-
           Ardea.Common.Module.throw_if_not_loaded(Ardea.Step, type, process: 2, validate: 1),
         {:ok, step} <- apply(step_module, :validate, [step]) do
      set_name_and_type(step, type, name)
    else
      {:error, reason} ->
        raise Ardea.Configuration.ConfigError,
              "Invalid step configuration of type #{type}. Reason: #{reason}"
    end
  end

  def validate(_step), do: raise(Ardea.Configuration.ConfigError, "Step without type encountered")

  defp set_name_and_type(step, type, name), do: Map.put(step, :type, type) |> Map.put(:name, name)

  def log_step_start(%{name: name}) when is_binary(name),
    do: Logger.info("Executing step '#{name}'")

  def log_step_start(%{type: type}), do: Logger.info("Executing unnamed '#{type}' step")
  def log_input_size(data), do: Logger.debug("Input size #{length(data)}")
end
