defmodule Ardea do
  use Application

  @impl true
  def start(_type, _args) do
    Ardea.Configuration.Reader.read()
    children = []
    opts = [strategy: :one_for_one, name: Ardea.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
