defmodule ElectronPhoenix.MinesweeperChannelTest do
  use ElectronPhoenix.ChannelCase

  alias ElectronPhoenix.MinesweeperChannel

  setup do
    {:ok, _, socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(MinesweeperChannel, "minesweeper:lobby")

    {:ok, socket: socket}
  end
end
