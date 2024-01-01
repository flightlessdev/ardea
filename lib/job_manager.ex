defmodule Ardea.JobManager do
  require Logger
  use GenServer
  alias Ardea.JobScheduler
  alias Ardea.Job

  def start_link(jobs) do
    GenServer.start_link(__MODULE__, jobs, name: __MODULE__)
  end

  @impl true
  def init(jobs) do
    Enum.each(jobs, fn {_key, job} -> initialize(job) end)
    {:ok, %{jobs: jobs}}
  end

  @impl true
  def handle_cast({:run, name, initial}, state) do
    jobs = Map.get(state, :jobs)
    job = Map.get(jobs, name)
    run_job(job, name, initial)
    # TODO: weird stuff if manual trigger of periodic job
    reschedule_periodic_job(job)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_jobs, _from, %{jobs: jobs} = state), do: {:reply, jobs, state}

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

  def run(name, initial) when is_map(initial) do
    run(name, [initial])
  end

  defp reschedule_periodic_job(%Job{
         name: name,
         trigger: :period,
         trigger_opts: [period: period],
         initial_data: data
       }) do
    Process.send_after(__MODULE__, {:run, name, data}, period * 1000)
  end

  defp reschedule_periodic_job(_), do: :ok

  defp initialize(
         %Job{
           trigger: :period
         } = job
       ) do
    reschedule_periodic_job(job)
  end

  defp initialize(%Job{
         trigger: :subscription,
         trigger_opts: trigger_opts
       }) do
    subscription_service = Keyword.get(trigger_opts, :subscription_service)

    opts = Keyword.get(trigger_opts, :subscription_opts)
    Ardea.Service.subscribe(subscription_service, opts)
  end

  defp initialize(%Job{
         name: name,
         trigger: :schedule,
         trigger_opts: [schedule: schedule],
         initial_data: data
       }) do
    JobScheduler.add_job({schedule, {__MODULE__, :run, [name, data]}})
  end

  defp initialize(job), do: job

  # Called by the subscription service to get all jobs subscribed to this service.
  # Further matching is service depenedent and have to be done there
  def get_subscribed_job(service_name) do
    GenServer.call(__MODULE__, :get_jobs)
    |> Enum.filter(&is_subscribed(&1, service_name))
    |> Enum.map(fn {_key, job} -> job end)
  end

  defp is_subscribed({_, %Job{trigger: :subscription, trigger_opts: opts}}, service_name) do
    Keyword.get(opts, :subscription_service) == service_name
  end

  defp is_subscribed(_, _), do: false
end
