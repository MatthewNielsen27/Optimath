defmodule Optimath do
  @moduledoc """
    Optimath

    A general purpose math library with a focus on parallel computing and speed
  """

  ##############################
  ##  General math constants  ##
  ##############################

  @pi 3.141592653589793238462643383

  @e 2.718281828459045235360287471

  @dx 0.00001

  ##############################
  ##  General math functions  ##
  ##############################

  @doc """
    Constant: Pi

    iex> Optimath.pi
    3.141592653589793238462643383
  """
  def pi, do: @pi

  @doc """
    Constant: e

    iex> Optimath.e
    2.718281828459045235360287471
  """
  def e, do: @e

  @doc """
    Function of e ^x

    iex> Optimath.e 2
    7.3890560989306495
  """
  def e(x), do: pow(@e, x)

  def pow(_number, 0), do: 1
  def pow(number, exponent), do: _pow(number, exponent, 1)

  @doc """
    Map a function over an enumerable in parallel

    iex> Optimath.map([1, 2], &(&1 * &1), 1_000)
    [1,4]
  """
  def map(enumerable, function, timeout) do
    enumerable
    |> Enum.map(&Task.async(fn -> function.(&1) end))
    |> Enum.map(&Task.await(&1, timeout))
  end

  @doc """
    Integral functtion that computes the value in a single chunk

    iex> Optimath.integral(fn(x) -> x end, 0, 1)
    0.5000050500001751
  """
  def integral(f, lowerBound, upperBound) do
    _parIntHelper(0, lowerBound, upperBound, f)
    |> _adjust
  end

  @doc """
    Integral function that computes the value in parallel chunks

    iex> Optimath.integral(fn(x) -> (x * x) + 1 end, 0, 10, 2)
    343.3341376591582
  """
  def integral(f, lowerBound, upperBound, chunks) do
    range = upperBound - lowerBound

    inc = range / chunks

    0..(chunks - 1)
    |> Enum.map(&Task.async(fn -> _parIntHelper(0, &1 * inc + lowerBound, &1 * inc + inc, f) end))
    |> Enum.map(&Task.await(&1, 100_000))
    |> Enum.sum()
    |> _adjust
  end

  @doc """
    Fibinacci function optimized through the use of an agent cache of intermediary values

    iex> Optimath.fibinacci(200)
    280571172992510140037611932413038677189525
  """
  def fibinacci(n) do
    {:ok, agent} = Acc.start_link(%{1 => 1, 0 => 0})
    
    _fib(agent, n)
  end

  @doc """
    Determine the factorial of a number

    iex> Optimath.factorial(4)
    24
  """
  def factorial(n), do: _factorial(n, 1)

  @doc """
    Two-sum function that is commonly found in programming interviews
    
    iex> Optimath.two_sum([1,2,3,4], 5)
    [{3, 2}, {4, 1}]
  """
  def two_sum(enumerable, goal) do
    {results, _map} =
      Enum.reduce(enumerable, {[], %{}}, fn num1, container ->
        _containedWithin(container, num1, goal)
      end)

    results
  end



  ###############################
  ##  General stats functions  ##
  ###############################

  @doc """
    Histogram function to count the frequency of each number in a number set

    iex> Optimath.histogram([1,2,1,4,5,5])
    %{1 => 2, 2 => 1, 4 => 1, 5 => 2}

    iex> Optimath.histogram([])
    nil
  """
  def histogram([]), do: nil

  def histogram(dataset) do
    Enum.reduce(dataset, %{}, fn(x, acc) -> Map.update(acc, x, 1, &(&1 + 1)) end)
  end

  @doc """
    The mean average of a number set

    iex> Optimath.mean([1,2,3,4,5])
    3.0

    iex> Optimath.mean([])
    nil
  """
  def mean([]), do: nil
  def mean(dataset), do: _sum(dataset, 0) / length(dataset)

  @doc """
    The median or middle number of a number set

    iex> Optimath.median([1,2,3,4,5])
    3

    iex> Optimath.median([5,3,1,2,4])
    3

    iex> Optimath.median([])
    nil
  """
  def median([]), do: nil

  def median(dataset) do
    dataset = Enum.sort(dataset)
    len = length(dataset)

    if rem(len, 2) == 0 do
      (Enum.at(dataset, div(len, 2)) + Enum.at(dataset, div(len, 2) - 1)) / 2
    else
      Enum.at(dataset, div(len, 2))
    end
  end

  @doc """
    The modal value for an enumerable

    iex> Optimath.mode([1,2,1,1,3,5,7])
    %{count: 3, mode: 1}

    iex> Optimath.mode([1,2,1,1,3,5,7]).mode
    1

    iex> Optimath.mode([1,2,1,1,3,5,7]).count
    3

    iex> Optimath.mode([])
    nil
  """
  def mode([]), do: nil

  def mode(dataset) do
    dataset = Enum.sort(dataset)
    _mode(dataset, Enum.at(dataset, 0), 0, %{:mode => 0, :count => 0})
  end

  @doc """
    The sum of an enumerable

    iex> Optimath.sum([1,2,3,4,5])
    15

    iex> Optimath.sum([])
    0
  """
  def sum(data), do: _sum(data, 0)

  @doc """
    The harmonic mean of the dataset

    iex> Optimath.harmonic_mean([1,2,3,4,5])
    2.18978102189781

    iex> Optimath.harmonic_mean([0,1,2,3,4])
    :invalid_data

    iex> Optimath.harmonic_mean([])
    nil
  """
  def harmonic_mean([]), do: nil

  def harmonic_mean(dataset) do
    if _valid(dataset, 0) do
      length(dataset) / Enum.reduce(dataset, 0, fn x, acc -> acc + 1 / x end)
    else
      :invalid_data
    end
  end

  @doc """
    Percent deviation of each value in an enumerable compared to some normative value
    iex> Optimath.percent_dev([0,1,2,3,4])
    [-100.0, -50.0, 0.0, 50.0, 100.0]

    iex> Optimath.percent_dev(1,2)
    -50.0

    iex> Optimath.percent_dev([0,1,2,3,4], 1)
    [-100.0, 0.0, 100.0, 200.0, 300.0]

    iex> Optimath.percent_dev([0,1,2,3,4], 0)
    :invalid_norm
  """

  def percent_dev(dataset) do
    norm = mean(dataset)
    Enum.reduce(dataset, [], fn x, acc -> acc ++ [_percent_dev(x, norm)] end)
  end

  def percent_dev(_dataset, 0), do: :invalid_norm

  def percent_dev([head | tail], norm),
    do: Enum.reduce([head | tail], [], fn x, acc -> acc ++ [_percent_dev(x, norm)] end)

  def percent_dev(x, norm), do: _percent_dev(x, norm)

  @doc """
    The range of the enumerable

    iex> Optimath.range([1,2,3,4])
    %{:smallest => 1, :largest => 4}
  """
  def range([head | tail]), do: _range(tail, head, head)



  #########################
  ##  Private functions  ##
  #########################

  # Helper function to fix innacuracies caused by integration
  defp _adjust(x), do: x * 1.0000001

  # Helper function to compute the power of a number to some exponent
  defp _pow(_number, 0, acc), do: acc
  defp _pow(number, exponent, acc) when exponent > 0, do: _pow(number, exponent - 1, acc * number)
  defp _pow(number, exponent, acc) when exponent < 0, do: 1 / _pow(number, (exponent * -1) - 1, acc * number)

  # Helper function to compute the integral of a function over a given range
  defp _parIntHelper(acc, lower, upper, _f) when lower > upper, do: acc

  defp _parIntHelper(acc, lower, upper, f) do
    val = f.(lower) * @dx

    _parIntHelper(acc + val, lower + @dx, upper, f)
  end

  # Helper function for the 2-sum, to see if the number needed is contained in the map
  defp _containedWithin({acc, index}, num1, goal) do
    num2 = goal - num1

    acc =
      case Map.fetch(index, num2) do
        :error -> acc
        {:ok, :ok} -> acc ++ [{num1, num2}]
      end

    index = Map.put(index, num1, :ok)

    {acc, index}
  end

  # Helper function for fibinacci
  defp _fib(agent, n) do
    case Acc.get(agent, n) do
      :error ->
        val = _fib(agent, n - 1) + _fib(agent, n - 2)
        Acc.insert(agent, n, val)
        val

      {:ok, val} ->
        val
    end
  end

  # Helper function for mode
  defp _mode([], _val, _count, %{:mode => _head, :count => 1}), do: :no_mode
  defp _mode([], _val, _count, modeInfo), do: modeInfo

  defp _mode([head | tail], val, _count, modeInfo) when head != val,
    do: _mode(tail, head, 0, modeInfo)

  defp _mode([head | tail], _val, count, modeInfo) do
    if count + 1 > modeInfo[:count] do
      _mode(tail, head, count + 1, %{:mode => head, :count => count + 1})
    else
      _mode(tail, head, count + 1, modeInfo)
    end
  end

  # Helper function for sum
  defp _sum([], acc), do: acc
  defp _sum([head | tail], acc), do: _sum(tail, acc + head)

  # Helper function for harmonic mean
  defp _valid([], _invalid), do: true
  defp _valid([head | _tail], restriction) when head == restriction, do: false
  defp _valid([_head | tail], invalid), do: _valid(tail, invalid)

  # Helper function for percent deviation
  defp _percent_dev(val, norm), do: (val - norm) / norm * 100

  # Helper function for range
  defp _range([], small, large), do: %{:smallest => small, :largest => large}
  defp _range([head | tail], small, large) when head < small, do: _range(tail, head, large)
  defp _range([head | tail], small, large) when head > large, do: _range(tail, small, head)
  defp _range([_head | tail], small, large), do: _range(tail, small, large)

  # Helper function for factorial
  defp _factorial(0, acc), do: acc
  defp _factorial(val, acc), do: _factorial(val - 1, acc * val)
end
