defmodule Ardea.Step.Dummy do
  alias Ardea.Step
  @behaviour Step

  def process(data, _step) do
    [IO.inspect(data)]
  end

  def validate(step) do
    {:ok, step}
  end
end
