defmodule Ardea.Common.Secret do
  def read!(variable) do
    with {:value, value} <- read(variable), false <- variable == value do
      value
    else
      _ ->
        raise ArgumentError, "Could not read secret from '#{variable}'"
    end
  end

  def read(variable) do
    variable
    |> from(:file)
    |> from(:env)
    |> from(:variable)
  end

  defp from({:value, value}, _) when is_binary(value),
    do: {:value, value}

  defp(from(variable, :file) when is_binary(variable)) do
    with value <- System.get_env(variable),
         true <- is_binary(value),
         {:ok, content} <- File.read(value) do
      {:value, content}
    else
      _ -> variable
    end
  end

  defp from(variable, :env) do
    with value <- System.get_env(variable), true <- is_binary(value) do
      {:value, value}
    else
      _ -> variable
    end
  end

  defp from(variable, :variable) do
    {:value, variable}
  end
end
