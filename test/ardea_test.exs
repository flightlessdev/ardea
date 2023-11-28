defmodule ArdeaTest do
  use ExUnit.Case
  doctest Ardea

  test "greets the world" do
    assert Ardea.hello() == :world
  end
end
