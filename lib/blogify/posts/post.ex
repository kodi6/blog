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
    post
    |> cast(attrs, [:title, :description, :slug])
    |> unique_constraint(:title)
    |> build_slug()
    |> validate_required([:title, :description])
  end


  defp build_slug(changeset) do
    if title = get_field(changeset, :title) do
      slug = Slug.slugify(title)
      put_change(changeset, :slug, slug)
    else
      changeset
    end
  end


end
