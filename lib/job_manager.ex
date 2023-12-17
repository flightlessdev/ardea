defmodule Ardea.JobManager do
  require Logger
  use GenServer
  alias Ardea.Job

  def start_link(jobs) do
    GenServer.start_link(__MODULE__, jobs, name: __MODULE__)
  end

  @impl true
  def init(jobs) do
    {:ok, %{jobs: jobs}}
  end

  @impl true
  def handle_cast({:run, name, initial}, state) do
    jobs = Map.get(state, :jobs)
    job = Map.get(jobs, name)
    run_job(job, name, initial)
    {:noreply, state}
  end

  defp run_job(nil, name, _) do
    Logger.error("Tried to start unknown job '#{name}'")
  end

  defp run_job(job, name, initial) do
    Logger.info("Starting job #{name}")
    start = :os.system_time(:millisecond)
    Job.run(job, initial)
    time = :os.system_time(:millisecond) - start
    Logger.info("Job #{name} ended. Runtime #{time} ms")
  end

  def run(name) do
    run(name, [])
  end

  def run(name, initial) when is_list(initial) do
    GenServer.cast(__MODULE__, {:run, name, initial})
  end
end
