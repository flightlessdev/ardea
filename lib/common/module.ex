defmodule Ardea.Common.Module do
  def throw_if_not_loaded(parent, module, functions \\ []) do
    module = String.downcase(module) |> Macro.camelize() |> String.to_atom()
    module = Module.concat(parent, module)

    with {:module, module} = Code.ensure_loaded(module),
         :ok <-
           Enum.each(functions, fn {function, arity} ->
             if !Kernel.function_exported?(module, function, arity) do
               raise Ardea.Configuration.ConfigError,
                     "Module '#{module}' missing expected function #{function}/#{arity}"
             end
           end) do
      {:ok, module}
    else
      _ -> raise Ardea.Configuration.ConfigError, "Module '#{module}' does not exist"
    end
  end
end
