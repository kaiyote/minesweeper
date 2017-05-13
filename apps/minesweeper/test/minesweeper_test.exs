defmodule MinesweeperTest do
  use ExUnit.Case, async: true

  import Minesweeper.Util

  @seed_mines [[:blank, :blank, :blank, :blank, :blank, :mine,  :blank, :blank, :blank],
               [:mine,  :blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank],
               [:blank, :blank, :mine,  :blank, :blank, :blank, :blank, :blank, :blank],
               [:blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank],
               [:blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank],
               [:blank, :blank, :blank, :blank, :mine,  :blank, :blank, :blank, :blank],
               [:blank, :blank, :blank, :blank, :blank, :blank, :blank, :blank, :mine],
               [:mine,  :blank, :mine,  :blank, :blank, :blank, :blank, :blank, :blank],
               [:mine,  :blank, :blank, :mine,  :blank, :blank, :mine,  :blank, :blank]]

  @seed_field for _ <- 1..9, do: for _ <- 1..9, do: :blank

  test "can get state of gen_server", %{name: name} do
    assert Minesweeper.get_state(name) == %Minesweeper{field: @seed_field, mines: @seed_mines}
  end

  describe "pick" do
    test "pick will send {:lose, current_field} if you pick a mine", %{name: name} do
      {:lose, field} = Minesweeper.pick name, 0, 1

      assert field == @seed_mines
    end

    test "pick will update the tile correctly if you pick next to a mine", %{name: name} do
      {:ok, field} = Minesweeper.pick name, 0, 0

      assert field == nested_replace_at field, 0, 0, 1
    end

    test "pick will auto-expand if you pick a 0", %{name: name} do
      {:ok, field} = Minesweeper.pick name, 2, 0

      expected_field = [[:blank, 1, 0, 0, 1, :blank, :blank, :blank, :blank],
                        [:blank, 2, 1, 1, 1, :blank, :blank, :blank, :blank]] ++
                       for _ <- 1..7, do: for _ <- 1..9, do: :blank
      assert field == expected_field
    end

    test "will auto-expand correctly if you pick near the bottom-right corner", %{name: name} do
      {:ok, field} = Minesweeper.pick name, 8, 8

      expected_field = @seed_field
        |> nested_replace_at(8, 8, 0)
        |> nested_replace_at(7, 8, 1)
        |> nested_replace_at(7, 7, 2)
        |> nested_replace_at(8, 7, 1)
      assert field == expected_field
    end

    test "will not uncover a :flag", %{name: name} do
      field = Minesweeper.flag name, 0, 1
      {:ok, pick_field} = Minesweeper.pick name, 0, 1

      assert pick_field == field
    end

    test "will uncover a :maybe_flag", %{name: name} do
      Minesweeper.flag name, 0, 1
      Minesweeper.flag name, 0, 1
      {:lose, pick_field} = Minesweeper.pick name, 0, 1

      assert pick_field == @seed_mines
    end

    test "will do nothing on a number", %{name: name} do
      {:ok, field} = Minesweeper.pick name, 0, 0
      {:ok, pick_field} = Minesweeper.pick name, 0, 0

      assert pick_field == field
    end
  end

  describe "flag" do
    test "will cycle from :blank, to :flag, to :maybe_flag, back to :blank", %{name: name} do
      expected_field = nested_replace_at @seed_field, 0, 0, :flag
      assert Minesweeper.flag(name, 0, 0) == expected_field

      expected_field = nested_replace_at expected_field, 0, 0, :maybe_flag
      assert Minesweeper.flag(name, 0, 0) == expected_field

      assert Minesweeper.flag(name, 0, 0) == @seed_field
    end

    test "will do nothing if you try to flag a number", %{name: name} do
      {:ok, field} = Minesweeper.pick name, 0, 0
      assert Minesweeper.flag(name, 0, 0) == field
    end
  end

  describe "force pick" do
    test "will not expand if not enough flags", %{name: name} do
      {:ok, field} = Minesweeper.pick name, 1, 1
      {:ok, force_pick_field} = Minesweeper.force_pick name, 1, 1
      assert field == force_pick_field
    end

    test "will expand if enough flags", %{name: name} do
      {:ok, _} = Minesweeper.pick name, 1, 1
      Minesweeper.flag name, 0, 1
      Minesweeper.flag name, 2, 2
      {:ok, field} = Minesweeper.force_pick name, 1, 1

      expected_field = [[1,     1, 0,     0,      1, :blank, :blank, :blank, :blank],
                        [:flag, 2, 1,     1,      1, :blank, :blank, :blank, :blank],
                        [1,     2, :flag, :blank, :blank, :blank, :blank, :blank, :blank]] ++
                        for _ <- 1..6, do: for _ <- 1..9, do: :blank
      assert field == expected_field
    end

    test "will bomb if flags are set incorrectly", %{name: name} do
      {:ok, _} = Minesweeper.pick name, 0, 0
      Minesweeper.flag name, 1, 0
      {:lose, field} = Minesweeper.force_pick name, 0, 0

      expected_field = @seed_mines
        |> nested_replace_at(0, 0, 1)
        |> nested_replace_at(1, 0, :flag)

      assert field == expected_field
    end

    test "will not expand on not a number", %{name: name} do
      {:ok, _} = Minesweeper.pick name, 0, 0
      field = Minesweeper.flag name, 0, 1

      {:ok, force_field} = Minesweeper.force_pick name, 0, 1
      assert field == force_field
      {:ok, force_field} = Minesweeper.force_pick name, 1, 1
      assert field == force_field
      field = Minesweeper.flag name, 0, 1
      {:ok, force_field} = Minesweeper.force_pick name, 0, 1
      assert field == force_field
    end
  end

  test "can determine when you have won by pick", %{name: name} do
    Minesweeper.pick name, 0, 0
    Minesweeper.pick name, 2, 0
    Minesweeper.pick name, 8, 0
    Minesweeper.pick name, 0, 3
    Minesweeper.pick name, 8, 8
    Minesweeper.pick name, 1, 7
    Minesweeper.pick name, 1, 8
    Minesweeper.pick name, 2, 8
    Minesweeper.pick name, 4, 6
    Minesweeper.pick name, 4, 7
    Minesweeper.pick name, 3, 7
    Minesweeper.pick name, 4, 8
    {status, _} = Minesweeper.pick name, 5, 8

    assert status == :win
  end

  test "can determine when you have won by force_pick", %{name: name} do
    Minesweeper.pick name, 0, 0
    Minesweeper.pick name, 2, 0
    Minesweeper.pick name, 8, 0
    Minesweeper.pick name, 0, 3
    Minesweeper.pick name, 8, 8
    Minesweeper.pick name, 1, 7
    Minesweeper.pick name, 1, 8
    Minesweeper.pick name, 2, 8
    Minesweeper.pick name, 4, 6
    Minesweeper.pick name, 4, 7
    Minesweeper.pick name, 3, 7
    Minesweeper.pick name, 4, 8
    Minesweeper.flag name, 3, 8
    {status, _} = Minesweeper.force_pick name, 4, 8

    assert status == :win
  end

  setup context do
    {:ok, _} = Minesweeper.start_link context.test, :small
    _ = Minesweeper.set_state context.test, %Minesweeper{field: @seed_field, mines: @seed_mines}
    {:ok, name: context.test}
  end
end
