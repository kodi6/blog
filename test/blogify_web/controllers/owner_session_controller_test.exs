defmodule BlogifyWeb.OwnerSessionControllerTest do
  use BlogifyWeb.ConnCase, async: true

  import Blogify.AccountsFixtures

  setup do
    %{owner: owner_fixture()}
  end

  describe "POST /owners/log_in" do
    test "logs the owner in", %{conn: conn, owner: owner} do
      conn =
        post(conn, ~p"/owners/log_in", %{
          "owner" => %{"email" => owner.email, "password" => valid_owner_password()}
        })

      assert get_session(conn, :owner_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ owner.email
      assert response =~ ~p"/owners/settings"
      assert response =~ ~p"/owners/log_out"
    end

    test "logs the owner in with remember me", %{conn: conn, owner: owner} do
      conn =
        post(conn, ~p"/owners/log_in", %{
          "owner" => %{
            "email" => owner.email,
            "password" => valid_owner_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_blogify_web_owner_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the owner in with return to", %{conn: conn, owner: owner} do
      conn =
        conn
        |> init_test_session(owner_return_to: "/foo/bar")
        |> post(~p"/owners/log_in", %{
          "owner" => %{
            "email" => owner.email,
            "password" => valid_owner_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, owner: owner} do
      conn =
        conn
        |> post(~p"/owners/log_in", %{
          "_action" => "registered",
          "owner" => %{
            "email" => owner.email,
            "password" => valid_owner_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, owner: owner} do
      conn =
        conn
        |> post(~p"/owners/log_in", %{
          "_action" => "password_updated",
          "owner" => %{
            "email" => owner.email,
            "password" => valid_owner_password()
          }
        })

      assert redirected_to(conn) == ~p"/owners/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/owners/log_in", %{
          "owner" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/owners/log_in"
    end
  end

  describe "DELETE /owners/log_out" do
    test "logs the owner out", %{conn: conn, owner: owner} do
      conn = conn |> log_in_owner(owner) |> delete(~p"/owners/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :owner_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the owner is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/owners/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :owner_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
