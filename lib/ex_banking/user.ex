defmodule ExBanking.User do
  @type user :: String.t()
  @type amount :: number
  @type currency :: String.t()

  alias __MODULE__.{Consumer, Producer}

  @spec create(user) ::
          :ok
          | {:error, :wrong_arguments}
          | {:error, :user_already_exists}
  def create(user) when not is_binary(user) do
    {:error, :wrong_arguments}
  end

  def create(user) do
    with {:ok, producer} <- Producer.start_link(user),
         {:ok, _consumer} <- Consumer.start_link(producer) do
      :ok
    else
      _ -> {:error, :user_already_exists}
    end
  end

  @spec get_balance(user, currency) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments}
          | {:error, :user_does_not_exist}
          | {:error, :too_many_requests_to_user}
  def get_balance(user, currency)
      when not is_binary(user)
      when not is_binary(currency) do
    {:error, :wrong_arguments}
  end

  def get_balance(user, currency) do
    case :global.whereis_name(user) do
      :undefined ->
        {:error, :user_does_not_exist}

      pid ->
        GenStage.call(pid, {:get_balance, currency})
    end
  end

  @spec deposit(user, amount, currency) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments}
          | {:error, :user_does_not_exist}
          | {:error, :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when not is_binary(user)
      when not is_binary(currency)
      when not is_number(amount) or amount <= 0 do
    {:error, :wrong_arguments}
  end

  def deposit(user, amount, currency) do
    case :global.whereis_name(user) do
      :undefined ->
        {:error, :user_does_not_exist}

      pid ->
        GenStage.call(pid, {:deposit, amount, currency})
    end
  end

  @spec withdraw(user, amount, currency) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments}
          | {:error, :user_does_not_exist}
          | {:error, :too_many_requests_to_user}
          | {:error, :not_enough_money}
  def withdraw(user, amount, currency)
      when not is_binary(user)
      when not is_binary(currency)
      when not is_number(amount) or amount <= 0 do
    {:error, :wrong_arguments}
  end

  def withdraw(user, amount, currency) do
    case :global.whereis_name(user) do
      :undefined ->
        {:error, :user_does_not_exist}

      pid ->
        GenStage.call(pid, {:withdraw, amount, currency})
    end
  end

  @spec send(from_user :: user, to_user :: user, amount, currency) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error, :wrong_arguments}
          | {:error, :sender_does_not_exist}
          | {:error, :receiver_does_not_exist}
          | {:error, :too_many_requests_to_sender}
          | {:error, :too_many_requests_to_receiver}
          | {:error, :not_enough_money}
  def send(from_user, to_user, amount, currency)
      when not is_binary(from_user)
      when not is_binary(to_user)
      when not is_binary(currency)
      when not is_number(amount) or amount <= 0
      when from_user == to_user do
    {:error, :wrong_arguments}
  end

  def send(from_user, to_user, amount, currency) do
    case {:global.whereis_name(from_user), :global.whereis_name(to_user)} do
      {:undefined, _} ->
        {:error, :sender_does_not_exist}

      {_, :undefined} ->
        {:error, :receiver_does_not_exist}

      {from_pid, _to_pid} ->
        GenStage.call(from_pid, {:send, to_user, amount, currency})
    end
  end
end
