defmodule Blogify.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, Key: :slug}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :description, :string
    field :title, :string
    field :markup_text, :string
    field :slug, :string
    has_many :comments, Blogify.Comments.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    attrs = Map.merge(attrs, slug_map(attrs))
    post
    |> cast(attrs, [:title, :description, :markup_text, :slug])
    |> validate_required([:title, :description, :markup_text])
  end




  defp slug_map(%{"title" => title}) do
    slug = String.downcase(title) |> String.replace(" ", "-")
    %{"slug" => slug}
  end
end
