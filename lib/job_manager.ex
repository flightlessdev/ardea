defmodule Ardea.JobManager do
  require Logger
  use GenServer
  alias Ardea.Job

  def start_link(jobs) do
    GenServer.start_link(__MODULE__, jobs, name: __MODULE__)
  end

  @impl true
  def init(jobs) do
    Enum.each(jobs, &schedule_periodic_job/1)
    {:ok, %{jobs: jobs}}
  end

  @impl true
  def handle_cast({:run, name, initial}, state) do
    jobs = Map.get(state, :jobs)
    job = Map.get(jobs, name)
    run_job(job, name, initial)
    # TODO: weird stuff if manual trigger of periodic job
    schedule_periodic_job(job)
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

  defp schedule_periodic_job(%Job{
         name: name,
         trigger: :period,
         trigger_opts: [period: period],
         initial_data: data
       }) do
    Process.send_after(__MODULE__, {:run, name, data}, period * 1000)
  end

  defp schedule_periodic_job(_), do: :ok
end
