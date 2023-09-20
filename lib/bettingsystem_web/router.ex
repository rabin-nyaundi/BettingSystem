defmodule BettingsystemWeb.Router do
  use BettingsystemWeb, :router

  import BettingsystemWeb.UserAccountsAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BettingsystemWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user_accounts
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BettingsystemWeb do
    pipe_through :browser

    # get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", BettingsystemWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bettingsystem, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BettingsystemWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BettingsystemWeb do
    pipe_through [:browser, :redirect_if_user_accounts_is_authenticated]

    get "/", PageController, :home

    live_session :redirect_if_user_accounts_is_authenticated,
      on_mount: [{BettingsystemWeb.UserAccountsAuth, :redirect_if_user_accounts_is_authenticated}] do
      live "/user_acconts/register", UserAccountsRegistrationLive, :new
      live "/user_acconts/log_in", UserAccountsLoginLive, :new
      live "/user_acconts/reset_password", UserAccountsForgotPasswordLive, :new
      live "/user_acconts/reset_password/:token", UserAccountsResetPasswordLive, :edit
    end

    post "/user_acconts/log_in", UserAccountsSessionController, :create
  end

  scope "/", BettingsystemWeb do
    pipe_through [:browser, :require_authenticated_user_accounts]

    live_session :require_authenticated_user_accounts,
      on_mount: [{BettingsystemWeb.UserAccountsAuth, :ensure_authenticated}] do
      live "/home", BettingHomeLive, :index
      live "/user-bets", UserBetsLive, :index
      live "/bets/:bet_id", BetViewLive, :index
      live "/users/", UsersLive, :index
      live "/users/:user_id", UserDetailViewLive, :view
      live "/user_acconts/settings", UserAccountsSettingsLive, :edit
      live "/user_acconts/settings/confirm_email/:token", UserAccountsSettingsLive, :confirm_email
    end
  end

  scope "/", BettingsystemWeb do
    pipe_through [:browser]

    delete "/user_acconts/log_out", UserAccountsSessionController, :delete

    live_session :current_user_accounts,
      on_mount: [{BettingsystemWeb.UserAccountsAuth, :mount_current_user_accounts}] do
      live "/user_acconts/confirm/:token", UserAccountsConfirmationLive, :edit
      live "/user_acconts/confirm", UserAccountsConfirmationInstructionsLive, :new
    end
  end
end
