defmodule BlogifyWeb.OwnerConfirmationLiveTest do
  use BlogifyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blogify.AccountsFixtures

  alias Blogify.Accounts
  alias Blogify.Repo

  setup do
    %{owner: owner_fixture()}
  end

  describe "Confirm owner" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/owners/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, owner: owner} do
      token =
        extract_owner_token(fn url ->
          Accounts.deliver_owner_confirmation_instructions(owner, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/owners/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Owner confirmed successfully"

      assert Accounts.get_owner!(owner.id).confirmed_at
      refute get_session(conn, :owner_token)
      assert Repo.all(Accounts.OwnerToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/owners/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Owner confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_owner(owner)

      {:ok, lv, _html} = live(conn, ~p"/owners/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, owner: owner} do
      {:ok, lv, _html} = live(conn, ~p"/owners/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Owner confirmation link is invalid or it has expired"

      refute Accounts.get_owner!(owner.id).confirmed_at
    end
  end
end
