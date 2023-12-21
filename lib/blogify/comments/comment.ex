defmodule Blogify.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comments" do
    field :markup_text, :string
    belongs_to :post, Blogify.Posts.Post
    belongs_to :reader, Blogify.Posts.Reader



    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:markup_text, :post_id, :reader_id])
    |> validate_required([:markup_text, :post_id, :reader_id])
  end
end
