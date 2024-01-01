defmodule Ardea.Service.Mqtt.SubscriptionHandler do
  alias Ardea.{JobManager, Job}
  @behaviour ExMQTT.PublishHandler

  def handle_publish(%{topic: topic, payload: payload}, service_name: name) do
    JobManager.get_subscribed_job(name)
    |> Enum.filter(&should_trigger(&1, topic))
    |> Enum.each(&run_job(&1, topic, payload))
  end

  defp run_job(%Job{name: name}, topic, payload),
    do: JobManager.run(name, %{"topic" => topic, "payload" => payload})

  defp get_topic(%Job{trigger_opts: opts}) do
    Keyword.get(opts, :subscription_opts) |> Keyword.get(:topic)
  end

  defp should_trigger(job, topic),
    do: topic_match(get_topic(job), topic)

  defp topic_match(maybe_wildcard_topic, recieved_topic) do
    if not is_wildcard(maybe_wildcard_topic) do
      maybe_wildcard_topic == recieved_topic
    else
      match_wild_card(maybe_wildcard_topic, recieved_topic)
    end
  end

  defp is_wildcard(maybe_wildcard_topic) do
    String.contains?(maybe_wildcard_topic, "+") or String.ends_with?(maybe_wildcard_topic, "#")
  end

  defp match_wild_card(wildcard_topic, recieved_topic) do
    multilevel? = String.contains?(wildcard_topic, "#")
    wildcard_topic = String.split(wildcard_topic, "/", trim: true)
    recieved_topic = String.split(recieved_topic, "/", trim: true)

    if not multilevel? and length(wildcard_topic) != length(recieved_topic) do
      false
    else
      Enum.zip(wildcard_topic, recieved_topic)
      |> Enum.reduce(true, fn {w, r}, acc -> acc and level_match(w, r) end)
    end
  end

  defp level_match("#", _r), do: true
  defp level_match("+", _r), do: true
  defp level_match(w, r), do: w == r
end
