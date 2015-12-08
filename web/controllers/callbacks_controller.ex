defmodule CallbacksController do
  use ExMoney.Web, :controller

  require Logger

  alias ExMoney.User
  alias ExMoney.Login
  alias ExMoney.Repo

  import Ecto.Query

  def success(conn, params) do
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]

    user = User.by_customer_id(customer_id) |> Repo.one

    if user do
      changeset = Ecto.Model.build(user, :logins)
      |> Login.success_callback_changeset(%{saltedge_login_id: login_id})

      if changeset.valid? do
        case Repo.insert(changeset) do
          {:ok, login} ->
            spawn(fn -> ExMoney.Saltedge.Login.sync(user.id) end)

            put_resp_content_type(conn, "application/json")
            |> send_resp(200, "ok")
          {:error, changeset} ->
            Logger.warn("Success: Could not create Login for customer_id => #{customer_id}, changeset => #{changeset}")
            put_resp_content_type(conn, "application/json")
            |> send_resp(200, "ok")
        end
      else
        # log error
        Logger.warn("Success: Could not create Login for customer_id => #{customer_id}, changeset invalid => #{changeset}")
        put_resp_content_type(conn, "application/json")
        |> send_resp(200, "ok")
      end
    else
      Logger.warn("Success: Could not create Login for customer_id => #{customer_id}, User not found for customer_id => #{customer_id}")
      put_resp_content_type(conn, "application/json")
      |> send_resp(200, "ok")
    end
  end

  def failure(conn, params) do
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]

    user = User.by_customer_id(customer_id) |> Repo.one

    if user do
      changeset = Ecto.Model.build(user, :logins)
      |> Login.failure_callback_changeset(%{
        saltedge_login_id: login_id,
        last_fail_error_class: params["data"]["error_class"],
        last_fail_message: params["data"]["message"]
      })
      if changeset.valid? do
        case Repo.insert(changeset) do
          {:ok, login} ->
            put_resp_content_type(conn, "application/json")
            |> send_resp(200, "ok")
          {:error, changeset} ->
            # log error
            Logger.warn("Failure: Could not create Login for customer_id => #{customer_id}, changeset => #{changeset}")
            put_resp_content_type(conn, "application/json")
            |> send_resp(200, "ok")
        end
      else
        Logger.warn("Failure: Could not create Login for customer_id => #{customer_id}, changeset invalid => #{changeset}")
        put_resp_content_type(conn, "application/json")
        |> send_resp(200, "ok")
      end
    else
      Logger.warn("Failure: Could not create Login for customer_id => #{customer_id}, User not found for customer_id => #{customer_id}")
      put_resp_content_type(conn, "application/json")
      |> send_resp(200, "ok")
    end
  end

  def notify(conn, params) do
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]
    stage = params["data"]["stage"]

    user = User.by_customer_id(customer_id) |> Repo.one

    if user do
      login = Login
      |> where([l], l.user_id == ^user.id)
      |> where([l], l.saltedge_login_id == ^login_id)
      |> Repo.one

      changeset = Login.notify_callback_changeset(login, %{stage: stage})

      if changeset.valid? do
        case Repo.update(changeset) do
          {:ok, login} ->
            put_resp_content_type(conn, "application/json")
            |> send_resp(200, "ok")
          {:error, changeset} ->
            Logger.warn("Notify: Could not update Login for customer_id => #{customer_id}, changeset => #{changeset}")
            put_resp_content_type(conn, "application/json")
            |> send_resp(200, "ok")
        end
      else
        Logger.warn("Failure: Could not update Login for customer_id => #{customer_id}, changeset invalid => #{changeset}")
        put_resp_content_type(conn, "application/json")
        |> send_resp(200, "ok")
      end
    else
      Logger.warn("Failure: Could not update Login for customer_id => #{customer_id}, User not found for customer_id => #{customer_id}")
      put_resp_content_type(conn, "application/json")
      |> send_resp(200, "ok")
    end
  end

  def interactive(conn, params) do
    customer_id = params["data"]["customer_id"]
    login_id = params["data"]["login_id"]
    stage = params["data"]["stage"]
    html = params["data"]["html"]
    session_exp = params["data"]["session_expires_at"]
    interactive_fields_names = params["data"]["interactive_fields_names"]

    user = User.by_customer_id(customer_id) |> Repo.one

    if user do
      login = Login
      |> where([l], l.user_id == ^user.id)
      |> where([l], l.saltedge_login_id == ^login_id)
      |> Repo.one

      changeset = Login.interactive_callback_changeset(login, %{
        stage: stage,
        interactive_fields_names: interactive_fields_names,
        interactive_html: html
      })

      if changeset.valid? do
        case Repo.update(changeset) do
          {:ok, login} ->
            put_resp_content_type(conn, "application/json")
            |> send_resp(200, "ok")
          {:error, changeset} ->
            Logger.warn("Interactive: Could not update Login for customer_id => #{customer_id}, changeset => #{changeset}")
            put_resp_content_type(conn, "application/json")
            |> send_resp(200, "ok")
        end
      else
        Logger.warn("Interactive: Could not update Login for customer_id => #{customer_id}, changeset invalid => #{changeset}")
        put_resp_content_type(conn, "application/json")
        |> send_resp(200, "ok")
      end
    else
      Logger.warn("Interactive: Could not update Login for customer_id => #{customer_id}, User not found for customer_id => #{customer_id}")
      put_resp_content_type(conn, "application/json")
      |> send_resp(200, "ok")
    end
  end
end
