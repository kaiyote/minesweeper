defmodule ElectronPhoenix.MinesweeperChannel do
  @moduledoc false
  use ElectronPhoenix.Web, :channel

  alias Minesweeper

  def join("minesweeper:lobby", _, socket) do
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("new_game", %{"size" => size, "name" => name}, socket) when size in ~w(small medium large) do
    {:ok, _} = Minesweeper.start_link name, String.to_atom size
    field = Minesweeper.get_field name
    {:reply, {:ok, %{field: field}}, socket}
  end
  def handle_in("flag", %{"x" => x, "y" => y, "name" => name}, socket) do
    field = Minesweeper.flag name, x, y
    {:reply, {:ok, %{field: field}}, socket}
  end
  def handle_in("pick", %{"x" => x, "y" => y, "name" => name}, socket) do
    {status, field} = Minesweeper.pick name, x, y
    {:reply, {:ok, %{status: status, field: field}}, socket}
  end
  def handle_in("force_pick", %{"x" => x, "y" => y, "name" => name}, socket) do
    {status, field} = Minesweeper.force_pick name, x, y
    {:reply, {:ok, %{status: status, field: field}}, socket}
  end
  def handle_in("stop", %{"name" => name}, socket) do
    Minesweeper.stop name
    {:reply, :ok, socket}
  end
end
