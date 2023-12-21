defmodule Blogify.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :description, :string
    field :title, :string
    field :markup_text, :string
    belongs_to :owner, Blogify.Accounts.Owner
    has_many :comments, Blogify.Comments.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :description, :markup_text, :owner_id])
    |> validate_required([:title, :description, :markup_text, :owner_id])
  end
end
