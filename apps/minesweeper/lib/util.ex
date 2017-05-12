defmodule Minesweeper.Util do
  @moduledoc false

  @doc ~S"""
  Returns a 1-arity function that always returns `value`

  ## Example

      iex> five = const 5
      iex> five.(7)
      5
  """
  @spec const(any) :: (any -> any)
  def const(value), do: fn _ -> value end

  @doc ~S"""
  Takes a 2-arity function, and returns a new 2-arity function
  where the parameters are flipped.

  ## Example

      iex> flipped_duplicate = flip &List.duplicate/2
      iex> List.duplicate 0, 10
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      iex> flipped_duplicate.(10, 0)
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  """
  @spec flip((any, any -> any)) :: (any, any -> any)
  def flip(func) when is_function(func, 2), do: &func.(&2, &1)

  @doc ~S"""
  Given a function, returns a version where each parameter can be
  applied independently

  ## Example

      iex> adder = fn x, y -> x + y end
      iex> curried_adder = curry adder
      iex> adder.(1, 2)
      3
      iex> add_one = curried_adder.(1)
      iex> add_one.(2)
      3
  """
  @spec curry(fun) :: (any -> any) | any
  @spec curry(fun, non_neg_integer, [any]) :: (any -> any) | any
  def curry(func) do
    {_, arity} = :erlang.fun_info func, :arity
    curry func, arity, []
  end
  def curry(func, 0, arguments), do: Kernel.apply(func, Enum.reverse arguments)
  def curry(func, arity, arguments) do
    fn arg -> curry func, arity - 1, [arg | arguments] end
  end

  @doc ~S"""
  Replaces a value at a given row/column in a 2-dimensional array

  ## Example

      iex> list = [[0, 0, 0], [0, 0, 0]]
      iex> nested_replace_at list, 2, 1, 1
      [[0, 0, 0], [0, 0, 1]]
  """
  @spec nested_replace_at([[any]], x :: integer, y :: integer, any) :: [[any]]
  def nested_replace_at(nested_list, x, y, value) do
    List.update_at nested_list, y, &(List.replace_at &1, x, value)
  end
end
