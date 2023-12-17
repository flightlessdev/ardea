defmodule Ardea.Step do
  @callback validate(step :: map()) :: {:ok, step :: map()} | {:error, reason :: term}
  @callback process(data :: map(), step :: map()) :: data :: [map()]

  def step(%{"type" => type} = step, data) do
    # Module should always be valid due to validation
    module = String.downcase(type) |> Macro.camelize() |> String.to_existing_atom()
    step_module = Module.concat(Ardea.Step, module)
    Enum.flat_map(data, &apply(step_module, :process, [&1, step]))
  end

  def validate(%{"type" => type} = step) do
    with {:ok, step_module} <-
           Ardea.Common.Module.throw_if_not_loaded(Ardea.Step, type, process: 2, validate: 1),
         {:ok, step} <- apply(step_module, :validate, [step]) do
      step
    else
      {:error, reason} ->
        raise Ardea.Configuration.ConfigError,
              "Invalid step configuration of type #{type}. Reason: #{reason}"
    end
  end

  def validate(_step), do: raise(Ardea.Configuration.ConfigError, "Step without type encountered")
end
