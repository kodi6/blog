defmodule BlogifyWeb.OwnerAuthTest do
  use BlogifyWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Blogify.Accounts
  alias BlogifyWeb.OwnerAuth
  import Blogify.AccountsFixtures

  @remember_me_cookie "_blogify_web_owner_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BlogifyWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{owner: owner_fixture(), conn: conn}
  end

  describe "log_in_owner/3" do
    test "stores the owner token in the session", %{conn: conn, owner: owner} do
      conn = OwnerAuth.log_in_owner(conn, owner)
      assert token = get_session(conn, :owner_token)
      assert get_session(conn, :live_socket_id) == "owners_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_owner_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, owner: owner} do
      conn = conn |> put_session(:to_be_removed, "value") |> OwnerAuth.log_in_owner(owner)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, owner: owner} do
      conn = conn |> put_session(:owner_return_to, "/hello") |> OwnerAuth.log_in_owner(owner)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, owner: owner} do
      conn = conn |> fetch_cookies() |> OwnerAuth.log_in_owner(owner, %{"remember_me" => "true"})
      assert get_session(conn, :owner_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :owner_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_owner/1" do
    test "erases session and cookies", %{conn: conn, owner: owner} do
      owner_token = Accounts.generate_owner_session_token(owner)

      conn =
        conn
        |> put_session(:owner_token, owner_token)
        |> put_req_cookie(@remember_me_cookie, owner_token)
        |> fetch_cookies()
        |> OwnerAuth.log_out_owner()

      refute get_session(conn, :owner_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_owner_by_session_token(owner_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "owners_sessions:abcdef-token"
      BlogifyWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> OwnerAuth.log_out_owner()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if owner is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> OwnerAuth.log_out_owner()
      refute get_session(conn, :owner_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_owner/2" do
    test "authenticates owner from session", %{conn: conn, owner: owner} do
      owner_token = Accounts.generate_owner_session_token(owner)
      conn = conn |> put_session(:owner_token, owner_token) |> OwnerAuth.fetch_current_owner([])
      assert conn.assigns.current_owner.id == owner.id
    end

    test "authenticates owner from cookies", %{conn: conn, owner: owner} do
      logged_in_conn =
        conn |> fetch_cookies() |> OwnerAuth.log_in_owner(owner, %{"remember_me" => "true"})

      owner_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> OwnerAuth.fetch_current_owner([])

      assert conn.assigns.current_owner.id == owner.id
      assert get_session(conn, :owner_token) == owner_token

      assert get_session(conn, :live_socket_id) ==
               "owners_sessions:#{Base.url_encode64(owner_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, owner: owner} do
      _ = Accounts.generate_owner_session_token(owner)
      conn = OwnerAuth.fetch_current_owner(conn, [])
      refute get_session(conn, :owner_token)
      refute conn.assigns.current_owner
    end
  end

  describe "on_mount: mount_current_owner" do
    test "assigns current_owner based on a valid owner_token", %{conn: conn, owner: owner} do
      owner_token = Accounts.generate_owner_session_token(owner)
      session = conn |> put_session(:owner_token, owner_token) |> get_session()

      {:cont, updated_socket} =
        OwnerAuth.on_mount(:mount_current_owner, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_owner.id == owner.id
    end

    test "assigns nil to current_owner assign if there isn't a valid owner_token", %{conn: conn} do
      owner_token = "invalid_token"
      session = conn |> put_session(:owner_token, owner_token) |> get_session()

      {:cont, updated_socket} =
        OwnerAuth.on_mount(:mount_current_owner, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_owner == nil
    end

    test "assigns nil to current_owner assign if there isn't a owner_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        OwnerAuth.on_mount(:mount_current_owner, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_owner == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_owner based on a valid owner_token", %{conn: conn, owner: owner} do
      owner_token = Accounts.generate_owner_session_token(owner)
      session = conn |> put_session(:owner_token, owner_token) |> get_session()

      {:cont, updated_socket} =
        OwnerAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_owner.id == owner.id
    end

    test "redirects to login page if there isn't a valid owner_token", %{conn: conn} do
      owner_token = "invalid_token"
      session = conn |> put_session(:owner_token, owner_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: BlogifyWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = OwnerAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_owner == nil
    end

    test "redirects to login page if there isn't a owner_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: BlogifyWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = OwnerAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_owner == nil
    end
  end

  describe "on_mount: :redirect_if_owner_is_authenticated" do
    test "redirects if there is an authenticated  owner ", %{conn: conn, owner: owner} do
      owner_token = Accounts.generate_owner_session_token(owner)
      session = conn |> put_session(:owner_token, owner_token) |> get_session()

      assert {:halt, _updated_socket} =
               OwnerAuth.on_mount(
                 :redirect_if_owner_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated owner", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               OwnerAuth.on_mount(
                 :redirect_if_owner_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_owner_is_authenticated/2" do
    test "redirects if owner is authenticated", %{conn: conn, owner: owner} do
      conn = conn |> assign(:current_owner, owner) |> OwnerAuth.redirect_if_owner_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if owner is not authenticated", %{conn: conn} do
      conn = OwnerAuth.redirect_if_owner_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_owner/2" do
    test "redirects if owner is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> OwnerAuth.require_authenticated_owner([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/owners/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> OwnerAuth.require_authenticated_owner([])

      assert halted_conn.halted
      assert get_session(halted_conn, :owner_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> OwnerAuth.require_authenticated_owner([])

      assert halted_conn.halted
      assert get_session(halted_conn, :owner_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> OwnerAuth.require_authenticated_owner([])

      assert halted_conn.halted
      refute get_session(halted_conn, :owner_return_to)
    end

    test "does not redirect if owner is authenticated", %{conn: conn, owner: owner} do
      conn = conn |> assign(:current_owner, owner) |> OwnerAuth.require_authenticated_owner([])
      refute conn.halted
      refute conn.status
    end
  end
end
