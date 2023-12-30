defmodule Ardea.JobScheduler do
  alias Ardea.JobManager
  use Quantum, otp_app: :ardea

  def get_cron_jobs(jobs) do
    cron_jobs =
      Enum.map(jobs, fn {_key, value} -> value end)
      |> Enum.filter(fn %Ardea.Job{trigger: trigger} -> trigger == :schedule end)
      |> Enum.map(&to_cronjob/1)

    [jobs: cron_jobs]
  end

  defp to_cronjob(%Ardea.Job{name: name, initial_data: data, trigger_opts: [schedule: schedule]}) do
    {schedule, {JobManager, :run, [name, data]}}
  end
end
