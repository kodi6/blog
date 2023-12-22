defmodule Blogify.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :description, :text
      add :markup_text, :text

      timestamps(type: :utc_datetime)
    end

  end
end
