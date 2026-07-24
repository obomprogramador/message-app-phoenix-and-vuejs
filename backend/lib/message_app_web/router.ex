defmodule MessageAppWeb.Router do
  use MessageAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug MessageAppWeb.Plugs.RateLimiter, limit: 100, period: 60
  end

  scope "/api", MessageAppWeb do
    pipe_through :api

    get "/health", HealthController, :index

    resources "/contacts", ContactController, only: [:index, :show, :create, :delete]

    get "/contacts/:contact_id/messages", MessageController, :index
    post "/contacts/:contact_id/messages", MessageController, :create
    get "/contacts/:contact_id/messages/search", MessageController, :search
    patch "/messages/:id/read", MessageController, :mark_as_read

    resources "/groups", GroupController do
      get "/members", GroupMemberController, :index
      post "/members", GroupMemberController, :create
      patch "/members/:contact_id", GroupMemberController, :update
      delete "/members/:contact_id", GroupMemberController, :delete

      get "/messages", GroupMessageController, :index
      post "/messages", GroupMessageController, :create
    end

  end

  if Application.compile_env(:message_app, :dev_routes) do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
    end
  end
end
