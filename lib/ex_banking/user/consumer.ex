defmodule ExBanking.User.Consumer do
  defmodule State do
    @type currency :: String.t()
    @type amount :: Decimal.t()

    @type t :: %__MODULE__{
            balance: %{} | %{optional(currency) => amount},
            pending: %{} | %{optional(currency) => amount}
          }

    defstruct balance: %{}, pending: %{}
  end

  use GenStage
  alias __MODULE__.State
  alias ExBanking.Arithmetics

  def start_link(name) do
    GenStage.start_link(__MODULE__, name)
  end

  @impl GenStage
  def init(name) do
    {:ok, producer} = ExBanking.User.Producer.start_link(name)
    {:consumer, %State{}, subscribe_to: [{producer, max_demand: 1}]}
  end

  @impl GenStage
  def handle_events([{:get_balance, currency, from}], _from, state) do
    currency_balance = state.balance[currency] || Arithmetics.zero()
    GenStage.reply(from, {:ok, Arithmetics.to_float(currency_balance)})

    {:noreply, [], state}
  end

  @impl GenStage
  def handle_events([{:deposit, amount, currency, from}], _from, state) do
    currency_balance = state.balance[currency] || Arithmetics.zero()

    new_currency_balance = Arithmetics.add(currency_balance, amount)
    GenStage.reply(from, {:ok, Arithmetics.to_float(new_currency_balance)})

    new_balance = Map.put(state.balance, currency, new_currency_balance)
    {:noreply, [], %{state | balance: new_balance}}
  end

  @impl GenStage
  def handle_events([{:withdraw, amount, currency, from}], _from, state) do
    currency_balance = state.balance[currency] || Arithmetics.zero()

    case Arithmetics.maybe_subtract(currency_balance, amount) do
      {:ok, new_currency_balance} ->
        GenStage.reply(from, {:ok, Arithmetics.to_float(new_currency_balance)})

        new_balance = Map.put(state.balance, currency, new_currency_balance)
        {:noreply, [], %{state | balance: new_balance}}

      {:error, :negative_result} ->
        GenStage.reply(from, {:error, :not_enough_money})
        {:noreply, [], state}
    end
  end

  @impl GenStage
  def handle_events([{:send, recipient, amount, currency, from}], _from, state) do
    with currency_balance = state.balance[currency] || Arithmetics.zero(),
         currency_pending = state.pending[currency] || Arithmetics.zero(),
         {:ok, new_currency_balance} <- Arithmetics.maybe_subtract(currency_balance, amount),
         new_currency_pending = Arithmetics.add(currency_pending, amount) do
      new_balance = Map.put(state.balance, currency, new_currency_balance)
      new_pending = Map.put(state.pending, currency, new_currency_pending)

      recipient_pid = :global.whereis_name(recipient)
      Process.send(recipient_pid, {:receive, self(), amount, currency, from}, [])

      {:noreply, [], %{state | balance: new_balance, pending: new_pending}}
    else
      {:error, :negative_result} ->
        GenStage.reply(from, {:error, :not_enough_money})
        {:noreply, [], state}
    end
  end

  @impl GenStage
  def handle_events([{:receive, sender, amount, currency, from}], _from, state) do
    currency_balance = state.balance[currency] || Arithmetics.zero()

    new_currency_balance = Arithmetics.add(currency_balance, amount)

    new_balance = Map.put(state.balance, currency, new_currency_balance)
    Process.send(sender, {:remove_pending, amount, currency, new_currency_balance, from}, [])
    {:noreply, [], %{state | balance: new_balance}}
  end

  @impl GenStage
  def handle_info({:reclaim_pending, amount, currency}, state) do
    currency_balance = state.balance[currency] || Arithmetics.zero()
    currency_pending = state.pending[currency] || Arithmetics.zero()

    new_currency_balance = Arithmetics.add(currency_balance, amount)
    {:ok, new_currency_pending} = Arithmetics.maybe_subtract(currency_pending, amount)

    new_balance = Map.put(state.balance, currency, new_currency_balance)
    new_pending = Map.put(state.pending, currency, new_currency_pending)

    {:noreply, [], %{state | balance: new_balance, pending: new_pending}}
  end

  @impl GenStage
  def handle_info({:remove_pending, amount, currency, recipient_balance, from}, state) do
    currency_balance = state.balance[currency] || Arithmetics.zero()
    currency_pending = state.pending[currency] || Arithmetics.zero()

    {:ok, new_currency_pending} = Arithmetics.maybe_subtract(currency_pending, amount)

    float_balance = Arithmetics.to_float(currency_balance)
    float_recipient_balance = Arithmetics.to_float(recipient_balance)

    new_pending = Map.put(state.pending, currency, new_currency_pending)

    GenStage.reply(from, {:ok, float_balance, float_recipient_balance})
    {:noreply, [], %{state | pending: new_pending}}
  end
end
