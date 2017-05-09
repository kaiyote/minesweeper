defmodule ElectronPhoenix.MinesweeperChannel do
  @moduledoc false
  use ElectronPhoenix.Web, :channel

  alias Minesweeper

  def join("minesweeper:lobby", _, socket) do
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("new_game", %{"size" => size}, socket) when size in ~w(small medium large) do
    {:ok, _} = Minesweeper.start_link(String.to_existing_atom size)
    field = Minesweeper.get_field
    {:reply, {:ok, %{field: field}}, socket}
  end
  def handle_in("flag", %{"x" => x, "y" => y}, socket) do
    field = Minesweeper.flag x, y
    {:reply, {:ok, %{field: field}}, socket}
  end
  def handle_in("pick", %{"x" => x, "y" => y}, socket) do
    {status, field} = Minesweeper.pick x, y
    {:reply, {:ok, %{status: status, field: field}}, socket}
  end
end
