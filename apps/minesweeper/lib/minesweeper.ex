defmodule Minesweeper do
  @moduledoc "The State for a game of minesweeper"

  use GenServer

  @typedoc "The Minesweeper GenServer state"
  @type t :: %__MODULE__{
    field: [[boolean | non_neg_integer]],
    mines: [[boolean]]
  }

  defstruct ~w(field mines)a

  @spec start_link(atom) :: GenServer.on_start
  def start_link(size) when size in ~w(small medium large)a do
    case GenServer.start_link __MODULE__, size, name: {:global, "minesweeper"} do
      {:error, {:already_started, pid}} ->
        # state server already exists when we want a new game
        # kill it and restart
        :ok = GenServer.stop pid
        GenServer.start_link __MODULE__, size, name: {:global, "minesweeper"}
      other -> other
    end
  end

  @spec init(atom) :: :ignore | {:ok, any} | {:stop, any} |
                      {:ok, any, :hibernate | :infinity | non_neg_integer()}
  def init(size) when size in ~w(small medium large)a do
    field = make_field size
    mines = seed_field field, size
    {:ok, %__MODULE__{field: field, mines: mines}}
  end

  @small_size 9
  @medium_size 16
  @large_width 30

  @spec make_field(atom) :: [[boolean]]
  @spec make_field(integer, integer) :: [[boolean]]
  def make_field(:small), do: make_field @small_size, @small_size
  def make_field(:medium), do: make_field @medium_size, @medium_size
  def make_field(:large), do: make_field @large_width, @medium_size
  def make_field(width, height) when width >= 9 and height >= 9 do
    for _ <- 1..height, do: for _ <- 1..width, do: false
  end

  @small_count 10
  @medium_count 40
  @large_count 99

  @spec seed_field([[boolean]], atom) :: [[boolean]]
  @spec seed_field([[boolean]], integer, integer, integer) :: [[boolean]]
  def seed_field(field, :small), do: seed_field field, @small_size, @small_size, @small_count
  def seed_field(field, :medium), do: seed_field field, @medium_size, @medium_size, @medium_count
  def seed_field(field, :large), do: seed_field field, @medium_size, @large_width, @large_count
  def seed_field(field, _, _, 0), do: field
  def seed_field(field, max_height, max_width, mine_count) do
    y = Enum.random(1..max_height) - 1
    x = Enum.random(1..max_width) - 1
    if field |> Enum.fetch!(y) |> Enum.fetch!(x) do
      seed_field field, max_height, max_width, mine_count
    else
      chosen_row = Enum.fetch! field, y
      updated_row = Enum.take(chosen_row, x) ++ [true] ++ Enum.drop(chosen_row, x + 1)
      updated_field = Enum.take(field, y) ++ [updated_row] ++ Enum.drop(field, y + 1)
      seed_field updated_field, max_height, max_width, mine_count - 1
    end
  end
end
