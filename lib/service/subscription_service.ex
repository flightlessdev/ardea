defmodule Ardea.Service.SubscriptionService do
  @callback subscribe(name :: binary(), opts :: keyword()) :: :ok
  @callback validate_subscription_opts(opts :: map()) ::
              {:ok, Keyword.t()} | {:error, binary()}
end
