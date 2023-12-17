defmodule Ardea.Service do
  require Logger

  def register_services(services) do
    :ets.new(__MODULE__, [:set, :public, :named_table])
    Enum.each(services, &:ets.insert(__MODULE__, &1))
    Enum.map(services, fn {_, service} -> service.child_spec end)
  end

  @type __MODULE__ :: [
          name: binary(),
          module: module(),
          child_spec: Supervisor.child_spec() | nil
        ]
  defstruct [
    :name,
    :module,
    :child_spec
  ]

  @callback validate(opts :: map(), name :: binary) :: Supervisor.child_spec() | nil
  @callback call(input :: map(), name :: binary()) :: [map()]

  def validate(services) when is_list(services) do
    Enum.map(services, &hd(validate(&1)))
  end

  def validate(%{"type" => type, "name" => name, "opts" => opts}) do
    Logger.info("Validating service #{name}")

    {:ok, service_module} =
      Ardea.Common.Module.throw_if_not_loaded(Ardea.Service, type, validate: 2, call: 2)

    [
      %__MODULE__{
        module: service_module,
        name: name,
        child_spec: apply(service_module, :validate, [opts, name])
      }
    ]
  end

  def call(input, name) do
    [{_, %__MODULE__{module: module}}] = :ets.lookup(__MODULE__, name)
    apply(module, :call, [input, name])
  end

  def exist?(name) do
    case :ets.lookup(__MODULE__, name) do
      [{_, %__MODULE__{module: _module}}] -> true
      _ -> false
    end
  end
end