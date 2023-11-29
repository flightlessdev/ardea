defmodule Ardea.Job do
  require Logger

  @type __MODULE__ :: [
          name: binary(),
          steps: [map()]
        ]
  defstruct [
    :name,
    :steps
  ]

  def run(%__MODULE__{name: name, steps: steps} = _job, initial) do
    Logger.info("Starting job #{name}")
    Enum.reduce(steps, initial, &Ardea.Step.step/2)
  end

  def validate(%{"name" => name, "steps" => steps}) do
    Logger.info("Validating job #{name}")
    %__MODULE__{name: name, steps: Enum.map(steps, &Ardea.Step.validate/1)}
  end

  def validate(_job), do: raise(Ardea.Configuration.ConfigError, "Job missing name and/or steps")
end
