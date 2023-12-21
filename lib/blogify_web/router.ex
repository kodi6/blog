defmodule BlogifyWeb.Router do
  use BlogifyWeb, :router

  import BlogifyWeb.OwnerAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlogifyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_owner
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BlogifyWeb do
    pipe_through :browser

    # get "/", PageController, :home

    live "/kodi", BlogLive.Index, :index
    live "/kodi/show", BlogLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlogifyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:blogify, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BlogifyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BlogifyWeb do
    pipe_through [:browser, :redirect_if_owner_is_authenticated]

    live_session :redirect_if_owner_is_authenticated,
      on_mount: [{BlogifyWeb.OwnerAuth, :redirect_if_owner_is_authenticated}] do
      live "/owners/register", OwnerRegistrationLive, :new
      live "/owners/log_in", OwnerLoginLive, :new
      live "/owners/reset_password", OwnerForgotPasswordLive, :new
      live "/owners/reset_password/:token", OwnerResetPasswordLive, :edit
    end

    post "/owners/log_in", OwnerSessionController, :create
  end

  scope "/", BlogifyWeb do
    pipe_through [:browser, :require_authenticated_owner]

    live_session :require_authenticated_owner,
      on_mount: [{BlogifyWeb.OwnerAuth, :ensure_authenticated}] do
      live "/owners/settings", OwnerSettingsLive, :edit
      live "/owners/settings/confirm_email/:token", OwnerSettingsLive, :confirm_email
    end
  end

  scope "/", BlogifyWeb do
    pipe_through [:browser]

    delete "/owners/log_out", OwnerSessionController, :delete

    live_session :current_owner,
      on_mount: [{BlogifyWeb.OwnerAuth, :mount_current_owner}] do
      live "/owners/confirm/:token", OwnerConfirmationLive, :edit
      live "/owners/confirm", OwnerConfirmationInstructionsLive, :new
    end
  end
end
