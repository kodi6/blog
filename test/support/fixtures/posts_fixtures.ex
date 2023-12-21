defmodule Blogify.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blogify.Posts` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        description: "some description",
        markup_text: "some markup_text",
        title: "some title"
      })
      |> Blogify.Posts.create_post()

    post
  end
end
