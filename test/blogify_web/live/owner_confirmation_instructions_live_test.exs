defmodule BlogifyWeb.OwnerConfirmationInstructionsLiveTest do
  use BlogifyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blogify.AccountsFixtures

  alias Blogify.Accounts
  alias Blogify.Repo

  setup do
    %{owner: owner_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/owners/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, owner: owner} do
      {:ok, lv, _html} = live(conn, ~p"/owners/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", owner: %{email: owner.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.OwnerToken, owner_id: owner.id).context == "confirm"
    end

    test "does not send confirmation token if owner is confirmed", %{conn: conn, owner: owner} do
      Repo.update!(Accounts.Owner.confirm_changeset(owner))

      {:ok, lv, _html} = live(conn, ~p"/owners/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", owner: %{email: owner.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.OwnerToken, owner_id: owner.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/owners/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", owner: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.OwnerToken) == []
    end
  end
end
