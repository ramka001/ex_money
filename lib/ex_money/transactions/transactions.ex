defmodule ExMoney.Transactions do
  import Ecto.Query, warn: false
  alias ExMoney.Repo

  alias ExMoney.Transactions.{Transaction, TransactionInfo}
  alias ExMoney.DateHelper

  def recent(user_id) do
    current_date = Timex.local
    from = Timex.shift(current_date, days: -7)

    query = from tr in Transaction,
      where: tr.made_on >= ^from,
      where: tr.user_id == ^user_id,
      preload: [:transaction_info, :category, :account],
      order_by: [desc: tr.inserted_at]

    Repo.all(query)
  end

  def for_month(date, account_id, user_id) do
    date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(date)
    to = DateHelper.last_day_of_month(date)
    account_ids = List.flatten([account_id])

    query = from tr in Transaction,
      preload: [:account, :category],
      where: tr.user_id == ^user_id,
      where: tr.made_on >= ^from,
      where: tr.made_on <= ^to,
      where: tr.account_id in ^account_ids

    Repo.all(query)
  end

  def for_month_grouped_by_category(date, account_id, user_id) do
    date = DateHelper.parse_date(date)
    from = DateHelper.first_day_of_month(date)
    to = DateHelper.last_day_of_month(date)

    query = from tr in Transaction,
      join: c in assoc(tr, :category),
      where: tr.made_on >= ^from,
      where: tr.made_on <= ^to,
      where: tr.account_id == ^account_id,
      where: tr.user_id == ^user_id,
      where: tr.amount < 0,
      group_by: [c.id],
      select: {c, sum(tr.amount)}

    transactions = Repo.all(query)

    Enum.reduce transactions, %{}, fn({category, amount}, acc) ->
      {float_amount, _} = Decimal.to_string(amount, :normal)
      |> Float.parse

      positive_float = float_amount * -1

      Map.put(acc, category.id,
        %{
          id: category.id,
          humanized_name: category.humanized_name,
          css_color: category.css_color,
          amount: positive_float,
          parent_id: category.parent_id
        }
      )
    end
  end
end
