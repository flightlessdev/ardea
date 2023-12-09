defmodule Ardea do
  alias Ardea.JobManager
  use Application

  @impl true
  def start(_type, _args) do
    jobs = Ardea.Configuration.Reader.read_jobs()
    children = [{JobManager, jobs}]
    opts = [strategy: :one_for_one, name: Ardea.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
