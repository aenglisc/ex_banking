defmodule ExBanking.User.Producer do
  defmodule State do
    @type t :: %__MODULE__{
            requests: ExBanking.BoundedQueue.t(),
            demand: integer
          }

    defstruct requests: ExBanking.BoundedQueue.new(10), demand: 0
  end

  use GenStage
  alias __MODULE__.State

  alias ExBanking.BoundedQueue

  def start_link(name) do
    GenStage.start_link(__MODULE__, %State{}, name: {:global, name})
  end

  @impl GenStage
  def init(%State{} = state) do
    {:producer, state}
  end

  @impl GenStage
  def handle_call({:get_balance, currency}, from, state) do
    request = {:get_balance, currency, from}

    case {BoundedQueue.enqueue(state.requests, request), state.demand} do
      {{:error, :queue_full}, _} ->
        {:reply, {:error, :too_many_requests_to_user}, [], state}

      {{:ok, requests}, 0} ->
        {:noreply, [], %{state | requests: requests}}

      {{:ok, _requests}, 1} ->
        {:noreply, [request], %{state | demand: 0}}
    end
  end

  @impl GenStage
  def handle_call({:deposit, amount, currency}, from, state) do
    request = {:deposit, amount, currency, from}

    case {BoundedQueue.enqueue(state.requests, request), state.demand} do
      {{:error, :queue_full}, _} ->
        {:reply, {:error, :too_many_requests_to_user}, [], state}

      {{:ok, requests}, 0} ->
        {:noreply, [], %{state | requests: requests}}

      {{:ok, _requests}, 1} ->
        {:noreply, [request], %{state | demand: 0}}
    end
  end

  @impl GenStage
  def handle_call({:withdraw, amount, currency}, from, state) do
    request = {:withdraw, amount, currency, from}

    case {BoundedQueue.enqueue(state.requests, request), state.demand} do
      {{:error, :queue_full}, _} ->
        {:reply, {:error, :too_many_requests_to_user}, [], state}

      {{:ok, requests}, 0} ->
        {:noreply, [], %{state | requests: requests}}

      {{:ok, _requests}, 1} ->
        {:noreply, [request], %{state | demand: 0}}
    end
  end

  @impl GenStage
  def handle_call({:send, recipient, amount, currency}, from, state) do
    request = {:send, recipient, amount, currency, from}

    case {BoundedQueue.enqueue(state.requests, request), state.demand} do
      {{:error, :queue_full}, _} ->
        {:reply, {:error, :too_many_requests_to_sender}, [], state}

      {{:ok, requests}, 0} ->
        {:noreply, [], %{state | requests: requests}}

      {{:ok, _requests}, 1} ->
        {:noreply, [request], %{state | demand: 0}}
    end
  end

  @impl GenStage
  def handle_info({:receive, sender, amount, currency, from}, state) do
    request = {:receive, sender, amount, currency, from}

    case {BoundedQueue.enqueue(state.requests, request), state.demand} do
      {{:error, :queue_full}, _} ->
        GenStage.reply(from, {:error, :too_many_requests_to_receiver})
        Process.send(sender, {:reclaim_pending, amount, currency}, [])

        {:noreply, [], state}

      {{:ok, requests}, 0} ->
        {:noreply, [], %{state | requests: requests}}

      {{:ok, _requests}, 1} ->
        {:noreply, [request], %{state | demand: 0}}
    end
  end

  @impl GenStage
  def handle_demand(1, state) do
    case BoundedQueue.dequeue(state.requests) do
      {:ok, {requests, request}} ->
        {:noreply, [request], %{state | requests: requests}}

      {:error, :queue_empty} ->
        {:noreply, [], %{state | demand: state.demand + 1}}
    end
  end
end
