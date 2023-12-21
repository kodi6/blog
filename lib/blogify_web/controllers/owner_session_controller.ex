defmodule BlogifyWeb.OwnerSessionController do
  use BlogifyWeb, :controller

  alias Blogify.Accounts
  alias BlogifyWeb.OwnerAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:owner_return_to, ~p"/owners/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"owner" => owner_params}, info) do
    %{"email" => email, "password" => password} = owner_params

    if owner = Accounts.get_owner_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> OwnerAuth.log_in_owner(owner, owner_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/owners/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> OwnerAuth.log_out_owner()
  end
end
