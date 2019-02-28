defmodule ExBanking.Arithmetics do
  @spec zero :: Decimal.t()
  def zero do
    0
    |> Decimal.new()
    |> Decimal.round(2)
  end

  @spec to_float(amount :: Decimal.t()) :: Float.t()
  def to_float(%Decimal{} = amount) do
    Decimal.to_float(amount)
  end

  @spec convert(amount :: number) :: Decimal.t()
  def convert(amount) do
    case amount do
      amount when is_float(amount) ->
        amount
        |> Decimal.from_float()
        |> Decimal.round(2)

      amount when is_integer(amount) ->
        amount
        |> Decimal.new()
        |> Decimal.round(2)
    end
  end

  @spec add(base :: Decimal.t(), amount :: number) :: Decimal.t()
  def add(%Decimal{} = current, amount)
      when is_number(amount) and amount >= 0 do
    amount
    |> convert
    |> Decimal.add(current)
    |> Decimal.round(2)
  end

  @spec maybe_subtract(base :: Decimal.t(), amount :: number) ::
          {:ok, Decimal.t()}
          | {:error, :negative_result}
  def maybe_subtract(%Decimal{} = current, amount)
      when is_number(amount) and amount >= 0 do
    result =
      amount
      |> convert
      |> Decimal.minus()
      |> Decimal.add(current)
      |> Decimal.round(2)

    if Decimal.negative?(result) do
      {:error, :negative_result}
    else
      {:ok, result}
    end
  end
end
