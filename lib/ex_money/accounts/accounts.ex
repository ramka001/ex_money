defmodule ExMoney.Accounts do
  import Ecto.Query, warn: false
  alias ExMoney.Repo

  alias ExMoney.Accounts.{Account}

  def get_account(account_id) do
    query = from a in Account,
      where: a.id == ^account_id,
      preload: [:login]

    Repo.one(query)
  end
end
