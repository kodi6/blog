defmodule Blogify.ReadersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blogify.Readers` context.
  """

  @doc """
  Generate a reader.
  """
  def reader_fixture(attrs \\ %{}) do
    {:ok, reader} =
      attrs
      |> Enum.into(%{
        email: "some email",
        name: "some name"
      })
      |> Blogify.Readers.create_reader()

    reader
  end
end
