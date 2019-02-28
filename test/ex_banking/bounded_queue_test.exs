defmodule ExBanking.BoundedQueueTest do
  use ExUnit.Case

  alias ExBanking.BoundedQueue

  describe "new/1" do
    test "default size 10" do
      expected_result = %BoundedQueue{queue: :queue.new(), size: 10}
      assert expected_result == BoundedQueue.new()
    end

    test "non-standard queue" do
      expected_result = %BoundedQueue{queue: :queue.new(), size: 1}
      assert expected_result == BoundedQueue.new(1)
    end
  end

  describe "current_length/1" do
    test "empty is zero" do
      queue = BoundedQueue.new()
      assert 0 == BoundedQueue.current_length(queue)
    end
  end

  describe "enqueue/2" do
    test "success" do
      queue = BoundedQueue.new(1)
      assert {:ok, _queue} = BoundedQueue.enqueue(queue, :a)
    end

    test "queue full" do
      queue = BoundedQueue.new(1)
      assert {:ok, queue} = BoundedQueue.enqueue(queue, :a)
      assert {:error, :queue_full} == BoundedQueue.enqueue(queue, :b)
    end
  end

  describe "dequeue/2" do
    test "success" do
      queue = BoundedQueue.new(1)
      assert {:ok, queue} = BoundedQueue.enqueue(queue, :a)
      assert {:ok, {_queue, :a}} = BoundedQueue.dequeue(queue)
    end

    test "queue empty" do
      queue = BoundedQueue.new(1)
      assert {:ok, queue} = BoundedQueue.enqueue(queue, :a)
      assert {:ok, {queue, :a}} = BoundedQueue.dequeue(queue)
      assert {:error, :queue_empty} == BoundedQueue.dequeue(queue)
    end
  end
end
