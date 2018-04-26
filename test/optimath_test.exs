defmodule OptimathTest do
  use ExUnit.Case
  doctest Optimath

  def equals(actual, accepted) do
    abs((actual - accepted) / (actual + accepted)) < 0.1
  end

  @enumerable [1, 2, 3, 4]

  test "integral of basic function" do
    f = fn x -> x end
    val = Optimath.integral(f, 0, 1)

    assert equals(val, 0.5)
  end

  test "integral of basic function calculated in parallel" do
    f = fn x -> x end
    val = Optimath.integral(f, 0, 1, 2)
    assert equals(val, 0.5)
  end

  test "map a function onto an enumerable in parallel" do
    f = fn x -> 2 * x end
    assert Optimath.map(@enumerable, f, 1000) == [2, 4, 6, 8]
  end
end
