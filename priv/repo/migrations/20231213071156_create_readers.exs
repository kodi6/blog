defmodule Blogify.Repo.Migrations.CreateReaders do
  use Ecto.Migration

  def change do
    create table(:readers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :email, :string

      timestamps(type: :utc_datetime)
    end
  end
end
