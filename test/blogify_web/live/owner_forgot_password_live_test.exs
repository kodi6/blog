defmodule BlogifyWeb.OwnerForgotPasswordLiveTest do
  use BlogifyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blogify.AccountsFixtures

  alias Blogify.Accounts
  alias Blogify.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/owners/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/owners/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/owners/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_owner(owner_fixture())
        |> live(~p"/owners/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{owner: owner_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, owner: owner} do
      {:ok, lv, _html} = live(conn, ~p"/owners/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", owner: %{"email" => owner.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Accounts.OwnerToken, owner_id: owner.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/owners/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", owner: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.OwnerToken) == []
    end
  end
end
