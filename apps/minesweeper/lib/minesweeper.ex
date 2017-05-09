defmodule Minesweeper do
  @moduledoc "The State for a game of minesweeper"

  use GenServer

  @typep field_t :: [[:blank | :flag | :maybe_flag | :mine | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8]]
  @typep mines_t :: [[:blank | :mine]]

  @typedoc "The Minesweeper GenServer state"
  @type t :: %__MODULE__{
    field: field_t,
    mines: mines_t
  }

  defstruct ~w(field mines)a

  @doc "This is a desktop client horrible wrapper around phoenix. There is only one game"
  @gen_server_name {:global, "minesweeper"}

  @spec start_link(atom) :: GenServer.on_start
  def start_link(size) when size in ~w(small medium large)a do
    case GenServer.start_link __MODULE__, size, name: @gen_server_name do
      {:error, {:already_started, pid}} ->
        # state server already exists when we want a new game
        # kill it and restart
        :ok = GenServer.stop pid
        GenServer.start_link __MODULE__, size, name: @gen_server_name
      other -> other
    end
  end

  @spec init(atom) :: :ignore | {:ok, t} | {:stop, any} |
                      {:ok, any, :hibernate | :infinity | non_neg_integer()}
  def init(size) when size in ~w(small medium large)a do
    field = make_field size
    mines = seed_field field, size
    {:ok, %__MODULE__{field: field, mines: mines}}
  end

  @spec stop() :: :ok
  def stop do
    GenServer.cast @gen_server_name, :stop
  end

  @spec show() :: :ok
  def show do
    GenServer.call @gen_server_name, :show
  end

  @spec flag(integer, integer) :: field_t
  def flag(x, y) do
    GenServer.call @gen_server_name, {:flag, x, y}
  end

  @spec pick(integer, integer) :: {:ok | :lose, field_t}
  def pick(x, y) do
    GenServer.call @gen_server_name, {:pick, x, y}
  end

  def handle_call(:show, _from, state), do: {:reply, to_string(state), state}
  def handle_call({:flag, x, y}, _from, state) do
    update_fun = fn val ->
      case val do
        :flag -> :maybe_flag
        :maybe_flag -> :blank
        :blank -> :flag
        x -> x
      end
    end
    new_state = %{state | field: update_position_fun(state.field, x, y, update_fun)}
    {:reply, new_state.field, new_state}
  end
  def handle_call({:pick, x, y}, _from, state) do
    case state.mines |> Enum.fetch!(y) |> Enum.fetch!(x) do
      :mine ->
        new_state = %{state | field: update_position(state.field, x, y, :mine)}
        {:reply, {:lose, new_state.field}, new_state}
      :blank ->
        new_state = %{state | field: uncover(state.field, state.mines, x, y)}
        {:reply, {:ok, new_state.field}, new_state}
    end
  end

  def handle_cast(:stop, state), do: {:stop, :normal, state}

  @small_size 9
  @medium_size 16
  @large_width 30

  @spec make_field(atom) :: field_t
  @spec make_field(integer, integer) :: field_t
  defp make_field(:small), do: make_field @small_size, @small_size
  defp make_field(:medium), do: make_field @medium_size, @medium_size
  defp make_field(:large), do: make_field @large_width, @medium_size
  defp make_field(width, height) when width >= 9 and height >= 9 do
    for _ <- 1..height, do: for _ <- 1..width, do: :blank
  end

  @small_count 10
  @medium_count 40
  @large_count 99

  @spec seed_field(field_t, atom) :: mines_t
  @spec seed_field(field_t, integer, integer, integer) :: mines_t
  defp seed_field(field, :small), do: seed_field field, @small_size, @small_size, @small_count
  defp seed_field(field, :medium), do: seed_field field, @medium_size, @medium_size, @medium_count
  defp seed_field(field, :large), do: seed_field field, @medium_size, @large_width, @large_count
  defp seed_field(field, _, _, 0), do: field
  defp seed_field(field, max_height, max_width, mine_count) do
    y = Enum.random(1..max_height) - 1
    x = Enum.random(1..max_width) - 1
    if field |> Enum.fetch!(y) |> Enum.fetch!(x) == :mine do
      seed_field field, max_height, max_width, mine_count
    else
      updated_field = update_position field, x, y, :mine
      seed_field updated_field, max_height, max_width, mine_count - 1
    end
  end

  @spec update_position(field_t, integer, integer, any) :: field_t
  defp update_position(field, x, y, value) when not is_function(value) do
    update_position_fun field, x, y, fn _ -> value end
  end

  @spec update_position_fun(field_t, integer, integer, (any -> any)) :: field_t
  defp update_position_fun(field, x, y, value_fun) when is_function(value_fun, 1) do
    chosen_row = Enum.fetch! field, y
    chosen_cell = Enum.fetch! chosen_row, x
    updated_row = Enum.take(chosen_row, x) ++ [value_fun.(chosen_cell)] ++ Enum.drop(chosen_row, x + 1)
    Enum.take(field, y) ++ [updated_row] ++ Enum.drop(field, y + 1)
  end

  @spec uncover(field_t, mines_t, integer, integer) :: field_t
  defp uncover(field, mines, x, y) do
    if field |> Enum.fetch!(y) |> Enum.fetch!(x) == :blank do
      case compute_touch_count mines, x, y do
        0 ->
          new_field = update_position field, x, y, 0
          max_y = Enum.count(mines) - 1
          max_x = Enum.count(Enum.fetch! mines, 0) - 1
          locations = for ix <- x - 1..x + 1,
                          iy <- y - 1..y + 1,
                          ix in 0..max_x,
                          iy in 0..max_y, do: {ix, iy}
          Enum.reduce locations, new_field, fn {x, y}, fld -> uncover fld, mines, x, y end
        count ->
          update_position field, x, y, count
      end
    else
      field
    end
  end

  @spec compute_touch_count(mines_t, integer, integer) :: integer
  defp compute_touch_count(mines, x, y) do
    max_y = Enum.count(mines) - 1
    max_x = Enum.count(Enum.fetch! mines, 0) - 1
    locations = for ix <- x - 1..x + 1,
                    iy <- y - 1..y + 1,
                    ix in 0..max_x,
                    iy in 0..max_y, do: {ix, iy}
    Enum.reduce locations, 0, fn {x, y}, acc ->
      if mines |> Enum.fetch!(y) |> Enum.fetch!(x) == :mine, do: acc + 1, else: acc end
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
