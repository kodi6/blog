defmodule Blogify.Readers do
  @moduledoc """
  The Readers context.
  """

  import Ecto.Query, warn: false
  alias Blogify.Repo

  alias Blogify.Readers.Reader

  @doc """
  Returns the list of readers.

  ## Examples

      iex> list_readers()
      [%Reader{}, ...]

  """
  def list_readers do
    Repo.all(Reader)
  end

  @doc """
  Gets a single reader.

  Raises `Ecto.NoResultsError` if the Reader does not exist.

  ## Examples

      iex> get_reader!(123)
      %Reader{}

      iex> get_reader!(456)
      ** (Ecto.NoResultsError)

  """
  def get_reader!(id), do: Repo.get!(Reader, id)

  @doc """
  Creates a reader.

  ## Examples

      iex> create_reader(%{field: value})
      {:ok, %Reader{}}

      iex> create_reader(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_reader(attrs \\ %{}) do
    %Reader{}
    |> Reader.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a reader.

  ## Examples

      iex> update_reader(reader, %{field: new_value})
      {:ok, %Reader{}}

      iex> update_reader(reader, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_reader(%Reader{} = reader, attrs) do
    reader
    |> Reader.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a reader.

  ## Examples

      iex> delete_reader(reader)
      {:ok, %Reader{}}

      iex> delete_reader(reader)
      {:error, %Ecto.Changeset{}}

  """
  def delete_reader(%Reader{} = reader) do
    Repo.delete(reader)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reader changes.

  ## Examples

      iex> change_reader(reader)
      %Ecto.Changeset{data: %Reader{}}

  """
  def change_reader(%Reader{} = reader, attrs \\ %{}) do
    Reader.changeset(reader, attrs)
  end
end
