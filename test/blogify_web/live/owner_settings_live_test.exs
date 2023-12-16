defmodule BlogifyWeb.OwnerSettingsLiveTest do
  use BlogifyWeb.ConnCase

  alias Blogify.Accounts
  import Phoenix.LiveViewTest
  import Blogify.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_owner(owner_fixture())
        |> live(~p"/owners/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if owner is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/owners/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/owners/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_owner_password()
      owner = owner_fixture(%{password: password})
      %{conn: log_in_owner(conn, owner), owner: owner, password: password}
    end

    test "updates the owner email", %{conn: conn, password: password, owner: owner} do
      new_email = unique_owner_email()

      {:ok, lv, _html} = live(conn, ~p"/owners/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "owner" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_owner_by_email(owner.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/owners/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "owner" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, owner: owner} do
      {:ok, lv, _html} = live(conn, ~p"/owners/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "owner" => %{"email" => owner.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_owner_password()
      owner = owner_fixture(%{password: password})
      %{conn: log_in_owner(conn, owner), owner: owner, password: password}
    end

    test "updates the owner password", %{conn: conn, owner: owner, password: password} do
      new_password = valid_owner_password()

      {:ok, lv, _html} = live(conn, ~p"/owners/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "owner" => %{
            "email" => owner.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/owners/settings"

      assert get_session(new_password_conn, :owner_token) != get_session(conn, :owner_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_owner_by_email_and_password(owner.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/owners/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "owner" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/owners/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "owner" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      owner = owner_fixture()
      email = unique_owner_email()

      token =
        extract_owner_token(fn url ->
          Accounts.deliver_owner_update_email_instructions(%{owner | email: email}, owner.email, url)
        end)

      %{conn: log_in_owner(conn, owner), token: token, email: email, owner: owner}
    end

    test "updates the owner email once", %{conn: conn, owner: owner, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/owners/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/owners/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_owner_by_email(owner.email)
      assert Accounts.get_owner_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/owners/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/owners/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, owner: owner} do
      {:error, redirect} = live(conn, ~p"/owners/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/owners/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_owner_by_email(owner.email)
    end

    test "redirects if owner is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/owners/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/owners/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
