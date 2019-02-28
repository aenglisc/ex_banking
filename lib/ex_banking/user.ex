defmodule ExBanking.User do
  @type user :: String.t()
  @type amount :: number
  @type currency :: String.t()

  @spec create(user) ::
          :ok
          | {:error, :wrong_arguments}
          | {:error, :user_already_exists}
  def create(user) when is_binary(user) do
    case :global.whereis_name(user) do
      :undefined ->
        ExBanking.User.Consumer.start_link(user)
        :ok

      _ ->
        {:error, :user_already_exists}
    end
  end

  def create(_), do: {:error, :wrong_arguments}

  @spec get_balance(user, currency) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments}
          | {:error, :user_does_not_exist}
          | {:error, :too_many_requests_to_user}
  def get_balance(user, currency)
      when is_binary(user) and
             is_binary(currency) do
    case :global.whereis_name(user) do
      :undefined ->
        {:error, :user_does_not_exist}

      pid ->
        GenStage.call(pid, {:get_balance, currency})
    end
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec deposit(user, amount, currency) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments}
          | {:error, :user_does_not_exist}
          | {:error, :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and
             is_number(amount) and amount > 0 and
             is_binary(currency) do
    case :global.whereis_name(user) do
      :undefined ->
        {:error, :user_does_not_exist}

      pid ->
        GenStage.call(pid, {:deposit, amount, currency})
    end
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user, amount, currency) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments}
          | {:error, :user_does_not_exist}
          | {:error, :too_many_requests_to_user}
          | {:error, :not_enough_money}
  def withdraw(user, amount, currency)
      when is_binary(user) and
             is_number(amount) and amount > 0 and
             is_binary(currency) do
    case :global.whereis_name(user) do
      :undefined ->
        {:error, :user_does_not_exist}

      pid ->
        GenStage.call(pid, {:withdraw, amount, currency})
    end
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec send(from_user :: user, to_user :: user, amount, currency) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error, :wrong_arguments}
          | {:error, :sender_does_not_exist}
          | {:error, :receiver_does_not_exist}
          | {:error, :too_many_requests_to_sender}
          | {:error, :too_many_requests_to_receiver}
          | {:error, :not_enough_money}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and
             is_binary(to_user) and
             is_number(amount) and amount > 0 and
             is_binary(currency) do
    case {:global.whereis_name(from_user), :global.whereis_name(to_user)} do
      {:undefined, _} ->
        {:error, :sender_does_not_exist}

      {_, :undefined} ->
        {:error, :receiver_does_not_exist}

      {pid, pid} ->
        {:error, :wrong_arguments}

      {from_pid, _to_pid} ->
        GenStage.call(from_pid, {:send, to_user, amount, currency})
    end
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}
end
