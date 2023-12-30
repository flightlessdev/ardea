defmodule Ardea do
  alias Ardea.{JobScheduler, JobManager}
  use Application

  @impl true
  def start(_type, _args) do
    services = Ardea.Configuration.Reader.read_services()

    jobs = Ardea.Configuration.Reader.read_jobs()

    children = [{JobManager, jobs}, {JobScheduler, JobScheduler.get_cron_jobs(jobs)} | services]
    opts = [strategy: :one_for_one, name: Ardea.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
