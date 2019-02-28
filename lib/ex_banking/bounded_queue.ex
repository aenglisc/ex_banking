defmodule ExBanking.BoundedQueue do
  @type t :: %__MODULE__{
          queue: {[any], [any]},
          size: integer
        }

  defstruct queue: :queue.new(), size: 10

  @spec new(size :: integer) :: queue :: t
  def new(size \\ 10), do: %__MODULE__{size: size}

  @spec current_length(queue :: t) :: integer
  def current_length(%__MODULE__{} = q) do
    :queue.len(q.queue)
  end

  @spec enqueue(queue :: t, item :: any) ::
          {:ok, queue :: t}
          | {:error, :queue_full}
  def enqueue(%__MODULE__{} = q, item) do
    if current_length(q) < q.size do
      {:ok, %{q | queue: :queue.in(item, q.queue)}}
    else
      {:error, :queue_full}
    end
  end

  @spec dequeue(queue :: t) ::
          {:ok, {queue :: t, item :: any}}
          | {:error, :queue_empty}
  def dequeue(%__MODULE__{} = q) do
    case :queue.out(q.queue) do
      {{:value, item}, queue} ->
        {:ok, {%{q | queue: queue}, item}}

      {:empty, _} ->
        {:error, :queue_empty}
    end
  end
end
