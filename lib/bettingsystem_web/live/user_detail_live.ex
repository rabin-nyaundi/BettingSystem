defmodule Bettingsystem.UserDetailView do
  use BettingsystemWeb, :live_view

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

  def render(assigns) do
    ~H"""
    Hello World
    """
  end

  def mount(_params, session, socket) do
    IO.inspect(session)
  end
end
