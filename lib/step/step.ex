defmodule Ardea.Step do
  @callback validate(step :: map()) :: {:ok, step :: map()} | {:error, reason :: term}
  @callback process(data :: map(), step :: map()) :: data :: [map()]

  def step(%{type: type} = step, data) do
    # Moduel should always be valid due to validation
    module = String.downcase(type) |> Macro.camelize() |> String.to_existing_atom()
    step_module = Module.concat(Ardea.Step, module)
    Enum.flat_map(data, &apply(step_module, :process, [&1, step]))
  end

  def validate(%{"type" => type} = step) do
    module = String.downcase(type) |> Macro.camelize() |> String.to_atom()
    step_module = Module.concat(Ardea.Step, module)
    throw_if_not_loaded(step_module, type)

    with {:ok, step} <- apply(step_module, :validate, [step]) do
      step
    else
      {:error, reason} ->
        raise Ardea.Configuration.ConfigError,
              "Invalid step configuration of type #{type}. Reason: #{reason}"
    end
  end

  def validate(_step), do: raise(Ardea.Configuration.ConfigError, "Step without type encountered")

  defp throw_if_not_loaded(module, type) do
    with {:module, module} = Code.ensure_loaded(module),
         true <-
           Kernel.function_exported?(module, :process, 2) &&
             Kernel.function_exported?(module, :validate, 1) do
      :ok
    else
      _ -> raise Ardea.Configuration.ConfigError, "Step type '#{type}' does not exist"
    end
  end
end
