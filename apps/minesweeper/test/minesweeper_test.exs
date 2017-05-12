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
    Minesweeper.pick 0, 0
    expected_field = List.update_at @seed_field, 0, fn row ->
      List.update_at row, 0, fn _ -> 1 end
    end
    assert Minesweeper.get_field == expected_field

    Minesweeper.pick 2, 0
    expected_field = [[1,      1,      0,      0,      1,      :blank, :blank, :blank, :blank],
                      [:blank, 2,      1,      1,      1,      :blank, :blank, :blank, :blank]] ++
                      for _ <- 1..7, do: for _ <- 1..9, do: :blank
    assert Minesweeper.get_field == expected_field
  end

  setup do
    Minesweeper.start_link :small
    Minesweeper.force_state %Minesweeper{
      field: @seed_field,
      mines: @seed_mines
    }
    :ok
  end
end
