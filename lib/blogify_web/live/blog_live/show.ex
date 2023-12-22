defmodule BlogifyWeb.BlogLive.Show do
  use BlogifyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    {:noreply, socket}
  end
end
