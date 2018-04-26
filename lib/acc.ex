defmodule Acc do
  use Agent

  def start_link(opts) do
    Agent.start_link(fn -> opts end)
  end

  def insert(acc, key, value) do
    Agent.update(acc, &Map.put(&1, key, value))
  end

  def get(acc, value) do
    Agent.get(acc, &Map.fetch(&1, value))
  end
end
