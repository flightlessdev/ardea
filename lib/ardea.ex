defmodule Ardea do
  alias Ardea.{JobScheduler, JobManager}
  use Application

  @impl true
  def start(_type, _args) do
    services = Ardea.Configuration.Reader.read_services()

    jobs = Ardea.Configuration.Reader.read_jobs()

    ## Order here matters due to job triggering
    children = services ++ [JobScheduler, {JobManager, jobs}]
    opts = [strategy: :one_for_one, name: Ardea.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
