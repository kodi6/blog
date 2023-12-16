defmodule Blogify.Readers.Reader do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "readers" do
    field :name, :string
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reader, attrs) do
    reader
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
  end
end
