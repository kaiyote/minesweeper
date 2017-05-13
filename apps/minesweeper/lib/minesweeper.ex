defmodule Minesweeper do
  @moduledoc "The State for a game of minesweeper"

  use GenServer

  alias Minesweeper.Util

  @typep field_t :: [[:blank | :flag | :maybe_flag | :mine | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8]]
  @typep mines_t :: [[:blank | :mine]]

  @typedoc "The Minesweeper GenServer state"
  @type t :: %__MODULE__{
    field: field_t,
    mines: mines_t
  }

  defstruct ~w(field mines)a

  @spec start_link(String.t, :small | :medium | :large) :: GenServer.on_start
  def start_link(name, size) do
    GenServer.start_link __MODULE__, size, name: {:global, "minesweeper:#{name}"}
  end

  @spec init(atom) :: :ignore | {:ok, t} | {:stop, any} |
                      {:ok, any, :hibernate | :infinity | non_neg_integer()}
  def init(size) when size in ~w(small medium large)a do
    height = get_dimension size, :height
    width = get_dimension size, :width
    field = make_field width, height
    mines = seed_field field, width, height, size
    {:ok, %__MODULE__{field: field, mines: mines}}
  end

  @spec show(String.t) :: String.t
  def show(name), do: GenServer.call {:global, "minesweeper:#{name}"}, :show

  @spec get_state(String.t) :: t
  def get_state(name), do: GenServer.call {:global, "minesweeper:#{name}"}, :get_state

  @spec get_field(String.t) :: field_t
  def get_field(name) do
    GenServer.call {:global, "minesweeper:#{name}"}, :get_field
  end

  @spec set_state(String.t, t) :: :ok
  def set_state(name, state) do
    GenServer.call {:global, "minesweeper:#{name}"}, {:set_state, state}
  end

  @spec flag(String.t, integer, integer) :: field_t
  def flag(name, x, y) do
    GenServer.call {:global, "minesweeper:#{name}"}, {:flag, x, y}
  end

  @spec pick(String.t, integer, integer) :: {:ok | :lose, field_t}
  def pick(name, x, y) do
    GenServer.call {:global, "minesweeper:#{name}"}, {:pick, x, y}
  end

  @spec force_pick(String.t, integer, integer) :: {:ok | :lose, field_t}
  def force_pick(name, x, y) do
    GenServer.call {:global, "minesweeper:#{name}"}, {:force_pick, x, y}
  end

  @spec stop(String.t) :: :ok
  def stop(name), do: GenServer.cast {:global, "minesweeper:#{name}"}, :stop

  def handle_call(:show, _from, state), do: {:reply, to_string(state), state}
  def handle_call(:get_state, _from, state), do: {:reply, state, state}
  def handle_call(:get_field, _from, state), do: {:reply, state.field, state}
  def handle_call({:set_state, new_state}, _from, _state), do: {:reply, :ok, new_state}
  def handle_call({:flag, x, y}, _from, %{field: field} = state) do
    new_field = case field |> Enum.fetch!(y) |> Enum.fetch!(x) do
      :blank -> Util.nested_replace_at field, x, y, :flag
      :flag -> Util.nested_replace_at field, x, y, :maybe_flag
      :maybe_flag -> Util.nested_replace_at field, x, y, :blank
      _ -> field
    end
    {:reply, new_field, %{state | field: new_field}}
  end
  def handle_call({:pick, x, y}, _from, %{field: field, mines: mines} = state) do
    {status, new_field} = uncover field, mines, x, y
    {:reply, {status, new_field}, %{state | field: new_field}}
  end
  def handle_call({:force_pick, x, y}, _from, %{field: field, mines: mines} = state) do
    {status, new_field} = force_uncover field, mines, x, y
    {:reply, {status, new_field}, %{state | field: new_field}}
  end

  def handle_cast(:stop, state), do: {:stop, :normal, state}

  @small_size 9
  @medium_size 16
  @large_width 30

  @spec make_field(integer, integer) :: field_t
  defp make_field(width, height) when width >= 9 and height >= 9 do
    for _ <- 1..height, do: for _ <- 1..width, do: :blank
  end

  @small_count 10
  @medium_count 40
  @large_count 99

  @spec seed_field(field_t, integer, integer, atom) :: mines_t
  @spec seed_field(field_t, integer, integer, integer) :: mines_t
  defp seed_field(field, w, h, :small), do: seed_field field, w, h, @small_count
  defp seed_field(field, w, h, :medium), do: seed_field field, w, h, @medium_count
  defp seed_field(field, w, h, :large), do: seed_field field, w, h, @large_count
  defp seed_field(field, _, _, 0), do: field
  defp seed_field(field, width, height, mine_count) do
    x = Enum.random(1..width) - 1
    y = Enum.random(1..height) - 1
    if field |> Enum.fetch!(y) |> Enum.fetch!(x) == :mine do
      seed_field field, width, height, mine_count
    else
      updated_field = Util.nested_replace_at field, x, y, :mine
      seed_field updated_field, width, height, mine_count - 1
    end
  end

  @spec get_dimension(:small | :medium | :large, :height | :width) :: integer
  defp get_dimension(:small, _), do: @small_size
  defp get_dimension(:medium, _), do: @medium_size
  defp get_dimension(:large, :height), do: @medium_size
  defp get_dimension(:large, :width), do: @large_width

  @spec uncover(field_t, mines_t, integer, integer) :: {:ok | :lose, field_t}
  defp uncover(field, mines, x, y) do
    combined_field = field |> Enum.zip(mines) |> Enum.map(fn {f, m} -> Enum.zip(f, m) end)
    case combined_field |> Enum.fetch!(y) |> Enum.fetch!(x) do
      {tile, _} when tile == :flag or is_integer(tile) -> {:ok, field} # its a flag, or uncovered
      {_, :mine} -> {:lose, reveal_mines(field, mines)} # BOOM
      {_, _} ->
        value = get_touch_count mines, x, y, :mine
        new_field = Util.nested_replace_at field, x, y, value
        if value == 0 do
          height = Enum.count(mines) - 1
          width = Enum.count(Enum.fetch! mines, 0) - 1
          check_positions = for i <- x - 1..x + 1,
                                j <- y - 1..y + 1,
                                i in 0..width,
                                j in 0..height, do: {i, j}
          Enum.reduce_while check_positions, {:ok, new_field}, fn
            {n_x, n_y}, {:ok, next_field} -> {:cont, uncover(next_field, mines, n_x, n_y)}
            {_, _}, {:lose, next_field} -> {:halt, {:lose, next_field}}
          end
        else
          {:ok, new_field}
        end
    end
  end

  defp force_uncover(field, mines, x, y) do
    height = Enum.count(mines) - 1
    width = Enum.count(Enum.fetch! mines, 0) - 1
    check_positions = for i <- x - 1..x + 1,
                          j <- y - 1..y + 1,
                          i in 0..width,
                          j in 0..height, do: {i, j}
    value = field |> Enum.fetch!(y) |> Enum.fetch!(x)
    if get_touch_count(field, x, y, :flag) == value do
      Enum.reduce_while check_positions, {:ok, field}, fn
        {n_x, n_y}, {:ok, next_field} -> {:cont, uncover(next_field, mines, n_x, n_y)}
        {_, _}, {:lose, next_field} -> {:halt, {:lose, next_field}}
      end
    else
      {:ok, field}
    end
  end

  @spec reveal_mines(field_t, mines_t) :: field_t
  defp reveal_mines(field, mines) do
    mines
    |> Enum.with_index()
    |> Enum.flat_map(fn {row, y} ->
      row |> Enum.with_index() |> Enum.map(fn {type, x} -> {type, {x, y}} end)
    end)
    |> Enum.filter_map(fn {type, _} -> type == :mine end, fn {_, pos} -> pos end)
    |> Enum.reduce(field, fn {x, y}, field -> Util.nested_replace_at(field, x, y, :mine) end)
  end

  @spec get_touch_count(mines_t | field_t, integer, integer, :mine | :flag) :: integer
  defp get_touch_count(mines, x, y, check_value) do
    height = Enum.count(mines) - 1
    width = Enum.count(Enum.fetch! mines, 0) - 1
    check_positions = for i <- x - 1..x + 1,
                          j <- y - 1..y + 1,
                          i in 0..width,
                          j in 0..height, do: {i, j}
    mines
    |> Enum.with_index()
    |> Enum.flat_map(fn {row, y} ->
      row |> Enum.with_index() |> Enum.map(fn {type, x} -> {type, {x, y}} end)
    end)
    |> Enum.filter(fn {type, pos} -> type == check_value && pos in check_positions end)
    |> Enum.count()
  end
end

defimpl String.Chars, for: Minesweeper do
  def to_string(%Minesweeper{field: field, mines: mines}) do
    field
    |> Enum.zip(mines)
    |> Enum.map_join("\n", fn {f, m} ->
      Enum.join(Enum.map(f, &map_to_char/1) ++
                [" ", " ", "|", " ", " "] ++
                Enum.map(m, &map_to_char/1))
    end)
  end

  defp map_to_char(:blank), do: "."
  defp map_to_char(:mine), do: "*"
  defp map_to_char(:flag), do: "⚑"
  defp map_to_char(:maybe_flag), do: "?"
  defp map_to_char(0), do: " "
  defp map_to_char(x), do: Integer.to_string x
end
