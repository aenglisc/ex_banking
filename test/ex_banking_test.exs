defmodule ExBankingTest do
  use ExUnit.Case

  describe "create_user/1" do
    test "success" do
      assert :ok == ExBanking.create_user("a")
    end

    test "user already exists" do
      assert :ok == ExBanking.create_user("a")
      assert {:error, :user_already_exists} == ExBanking.create_user("a")
    end

    test "wrong arguments" do
      assert {:error, :wrong_arguments} == ExBanking.create_user(1)
    end
  end

  describe "deposit/3" do
    test "success" do
      assert :ok == ExBanking.create_user("a")
      assert {:ok, 1.0} == ExBanking.deposit("a", 1, "USD")
    end

    test "user does not exist" do
      assert {:error, :user_does_not_exist} == ExBanking.deposit("a", 1, "USD")
    end

    test "negative amount" do
      assert {:error, :wrong_arguments} == ExBanking.deposit("a", -1, "USD")
    end
  end

  describe "withdraw/3" do
    test "success" do
      assert :ok == ExBanking.create_user("a")
      assert {:ok, 1.0} == ExBanking.deposit("a", 1, "USD")
      assert {:ok, 0.0} == ExBanking.withdraw("a", 1, "USD")
    end

    test "user does not exist" do
      assert {:error, :user_does_not_exist} == ExBanking.withdraw("a", 1, "USD")
    end

    test "not enough money" do
      assert :ok == ExBanking.create_user("a")
      assert {:error, :not_enough_money} == ExBanking.withdraw("a", 1, "USD")
    end

    test "negative amount" do
      assert {:error, :wrong_arguments} == ExBanking.withdraw("a", -1, "USD")
    end
  end

  describe "get_balance/2" do
    test "success" do
      assert :ok == ExBanking.create_user("a")
      assert {:ok, 0.0} == ExBanking.get_balance("a", "USD")
    end
  end

  describe "send/4" do
    test "success" do
      assert :ok == ExBanking.create_user("a")
      assert :ok == ExBanking.create_user("b")
      assert {:ok, 1.0} == ExBanking.deposit("a", 1, "USD")
      assert {:ok, 0.0, 1.0} == ExBanking.send("a", "b", 1, "USD")
    end

    test "sender does not exist" do
      assert :ok == ExBanking.create_user("b")
      assert {:error, :sender_does_not_exist} == ExBanking.send("a", "b", 1, "USD")
    end

    test "receiver does not exist" do
      assert :ok == ExBanking.create_user("a")
      assert {:error, :receiver_does_not_exist} == ExBanking.send("a", "b", 1, "USD")
    end

    test "not enough money" do
      assert :ok == ExBanking.create_user("a")
      assert :ok == ExBanking.create_user("b")
      assert {:error, :not_enough_money} == ExBanking.send("a", "b", 1, "USD")
    end

    test "send to self" do
      assert :ok == ExBanking.create_user("a")
      assert {:error, :wrong_arguments} == ExBanking.send("a", "a", 1, "USD")
    end
  end

  test "rate limiting" do
    assert :ok == ExBanking.create_user("d")
    assert :ok == ExBanking.create_user("e")

    assert {:ok, 1000.0} == ExBanking.deposit("d", 1000, "USD")
    assert {:ok, 1000.0} == ExBanking.deposit("e", 1000, "USD")

    assert true == rate_limited?()
  end

  defp rate_limited? do
    errors = [
      {:error, :too_many_requests_to_user},
      {:error, :too_many_requests_to_sender},
      {:error, :too_many_requests_to_receiver}
    ]

    stream =
      Task.async_stream(1..150, fn _ ->
        from = Enum.random(["d", "e"])
        to = Enum.random(["d", "e"] -- [from])

        for _ <- 1..5, do: spawn(fn -> ExBanking.get_balance(from, "USD") end)
        for _ <- 1..5, do: spawn(fn -> ExBanking.get_balance(to, "USD") end)
        for _ <- 1..5, do: spawn(fn -> ExBanking.deposit(to, 1, "USD") end)
        for _ <- 1..5, do: spawn(fn -> ExBanking.withdraw(from, 1, "USD") end)
        for _ <- 1..5, do: spawn(fn -> ExBanking.send(from, to, 1, "USD") end)
        for _ <- 1..5, do: spawn(fn -> ExBanking.send(to, from, 1, "USD") end)

        case :rand.uniform(3) do
          3 -> ExBanking.send(from, to, 1, "USD")
          2 -> ExBanking.deposit(to, 1, "USD")
          1 -> ExBanking.withdraw(from, 1, "USD")
        end
      end)

    stream
    |> Enum.map(fn {:ok, result} -> result end)
    |> Enum.any?(&(&1 in errors))
  end
end
