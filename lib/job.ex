defmodule Ardea.Job do
  alias Ardea.Configuration.ConfigError
  require Logger

  @type __MODULE__ :: [
          name: binary(),
          steps: [map()],
          trigger: :api | :subscription | :schedule | :period | :manual,
          trigger_opts: keyword(),
          initial_data: []
        ]
  defstruct [
    :name,
    :steps,
    :trigger,
    :trigger_opts,
    :initial_data
  ]

  def run(%__MODULE__{steps: steps} = _job, initial) do
    Enum.reduce(steps, initial, &Ardea.Step.step/2)
  end

  def validate(%{"name" => name, "steps" => steps, "trigger" => trigger} = job) do
    Logger.info("Validating job #{name}")
    {trigger, trigger_opts} = validate_trigger(trigger, job)

    %__MODULE__{
      name: name,
      steps: Enum.map(steps, &Ardea.Step.validate/1),
      trigger: trigger,
      trigger_opts: trigger_opts,
      initial_data: get_initial_data(job)
    }
  end

  def validate(_job), do: raise(ConfigError, "Job missing one or more required fields")

  defp get_initial_data(%{"initial_data" => data}) when is_list(data), do: data
  defp get_initial_data(%{"initial_data" => data}) when is_map(data), do: [data]
  defp get_initial_data(_job), do: []

  # TODO: implement
  defp validate_trigger("api", _job), do: raise(ConfigError, "Api trigger not implemented yet")

  defp validate_trigger("subscription", job) do
    subscription_service = Map.fetch!(job, "subscription_service")
    subscription_opts = Map.fetch!(job, "subscription_opts")

    if !Ardea.Service.supports_subscription?(subscription_service) do
      raise ConfigError, "Service #{subscription_service} does not support subscriptions"
    end

    subscription_opts =
      Ardea.Service.validate_subscription_opts(subscription_service, subscription_opts)

    {:subscription, subscription_opts}
  end

  defp validate_trigger("schedule", job) do
    schedule = Map.fetch!(job, "schedule")
    Crontab.CronExpression.Parser.parse!(schedule)

    {:schedule, [schedule: schedule]}
  end

  defp validate_trigger("period", job) do
    period = Map.fetch!(job, "period")

    if not is_integer(period) do
      raise ConfigError, "Period is not integer"
    end

    {:period, [period: period]}
  end

  defp validate_trigger("manual", _job) do
    {:manual, []}
  end

  defp validate_trigger(trigger, _job), do: raise(ConfigError, "Unknown trigger: #{trigger}")
end
