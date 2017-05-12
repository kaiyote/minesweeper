defmodule MinesweeperTest do
  use ExUnit.Case
  doctest Minesweeper

  @seed_mines [[:blank, :blank, :blank, :blank, :blank, :mine,  :blank, :blank, :blank],
               [:mine,  :blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank],
               [:blank, :blank, :mine,  :blank, :blank, :blank, :blank, :blank, :blank],
               [:blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank],
               [:blank, :blank, :blank, :blank, :mine,  :blank, :blank, :blank, :blank],
               [:blank, :blank, :blank, :blank, :mine,  :blank, :blank, :blank, :blank],
               [:blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank],
               [:mine,  :blank, :mine,  :blank, :blank, :blank, :blank, :blank, :blank],
               [:mine,  :blank, :blank, :mine,  :blank, :blank, :blank, :mine,  :blank]]

  @seed_field for _ <- 1..9, do: for _ <- 1..9, do: :blank

  test "get_field / get_mines" do
    assert Minesweeper.get_field == @seed_field
    assert Minesweeper.get_mines == @seed_mines
  end

  test "pick" do
    expected_field = List.update_at @seed_field, 0, &(List.update_at &1, 0, const 1)
    assert Minesweeper.pick(0, 0) == {:ok, expected_field}


    expected_field = [[1,      1, 0, 0, 1, :blank, :blank, :blank, :blank],
                      [:blank, 2, 1, 1, 1, :blank, :blank, :blank, :blank]] ++
                      for _ <- 1..7, do: for _ <- 1..9, do: :blank
    assert Minesweeper.pick(2, 0) == {:ok, expected_field}
    assert Minesweeper.pick(2, 0) == {:ok, expected_field}

    expected_field = List.update_at expected_field, 1, &(List.update_at &1, 0, const :mine)
    assert Minesweeper.pick(0, 1) == {:lose, expected_field}
  end

  test "flag" do
    Minesweeper.pick 0, 0
    Minesweeper.pick 2, 0

    expected_field = [[1,      1, 0, 0, 1, :blank, :blank, :blank, :blank],
                      [:flag,  2, 1, 1, 1, :blank, :blank, :blank, :blank]] ++
                      for _ <- 1..7, do: for _ <- 1..9, do: :blank
    assert Minesweeper.flag(0, 1) == expected_field
    assert Minesweeper.pick(0, 1) == expected_field

    expected_field = List.update_at expected_field, 1, &(List.update_at &1, 0, const :maybe_flag)
    assert Minesweeper.flag(0, 1) == expected_field

    expected_field = List.update_at expected_field, 1, &(List.update_at &1, 0, const :blank)
    assert Minesweeper.flag(0, 1) == expected_field

    assert Minesweeper.flag(0, 0) == expected_field
  end

  setup do
    Minesweeper.start_link :small
    Minesweeper.force_state %Minesweeper{
      field: @seed_field,
      mines: @seed_mines
    }
    :ok
  end

  defp const(val) do
    fn _ -> val end
  end
end
