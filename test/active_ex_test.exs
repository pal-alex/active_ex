defmodule ActiveExTest do
  use ExUnit.Case
  doctest ActiveEx

  test "greets the world" do
    assert ActiveEx.hello() == :world
  end
end
