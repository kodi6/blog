defmodule BlogifyWeb.BlogLive.Index do
  use BlogifyWeb, :live_view

  alias Blogify.Posts.Post
  alias Blogify.Posts

  @impl true
  def mount(_param, _session, socket) do
    posts = Posts.list_posts()
    limited_posts = Enum.take(posts, 3)
    {:ok, stream(socket, :posts, limited_posts)}
  end
end
