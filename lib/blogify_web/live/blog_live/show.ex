defmodule BlogifyWeb.BlogLive.Show do
  use BlogifyWeb, :live_view

    alias Blogify.Posts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    {:noreply,
    socket
    |> assign(:post, Posts.get_post_by_slug(slug))
  }
  end


end
