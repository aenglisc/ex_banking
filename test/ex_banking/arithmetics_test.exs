defmodule ExBanking.ArithmeticsTest do
  use ExUnit.Case

  alias ExBanking.Arithmetics

  describe "zero/0" do
    test "is zero with 2 decimal points" do
      expected_result =
        0
        |> Decimal.new()
        |> Decimal.round(2)

      assert expected_result == Arithmetics.zero()
    end
  end

  describe "to_float/1" do
    test "makes a float" do
      result =
        Arithmetics.zero()
        |> Arithmetics.to_float()

      assert 0.0 == result
    end
  end

  describe "convert/1" do
    test "float to dec" do
      result =
        1.777
        |> Arithmetics.convert()
        |> Arithmetics.to_float()

      assert 1.78 == result
    end

    test "int to dec" do
      result =
        1
        |> Arithmetics.convert()
        |> Arithmetics.to_float()

      assert 1.0 == result
    end
  end

  describe "add/2" do
    test "add float" do
      result =
        Arithmetics.zero()
        |> Arithmetics.add(1.1)
        |> Arithmetics.to_float()

      assert 1.1 == result
    end

    test "add int" do
      result =
        Arithmetics.zero()
        |> Arithmetics.add(2)
        |> Arithmetics.to_float()

      assert 2.0 == result
    end
  end

  describe "maybe_subtract/2" do
    test "success: subtract float" do
      result =
        2
        |> Arithmetics.convert()
        |> Arithmetics.maybe_subtract(1.1)

      assert {:ok, %Decimal{} = decimal} = result
      assert 0.9 == Arithmetics.to_float(decimal)
    end

    test "success: subtract int" do
      result =
        2
        |> Arithmetics.convert()
        |> Arithmetics.maybe_subtract(1)

      assert {:ok, %Decimal{} = decimal} = result
      assert 1.0 == Arithmetics.to_float(decimal)
    end

    test "error: subtract float" do
      result =
        2
        |> Arithmetics.convert()
        |> Arithmetics.maybe_subtract(2.1)

      assert {:error, :negative_result} == result
    end

    test "error: subtract int" do
      result =
        2
        |> Arithmetics.convert()
        |> Arithmetics.maybe_subtract(3)

      assert {:error, :negative_result} == result
    end
  end
end
