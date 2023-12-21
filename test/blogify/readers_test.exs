defmodule Blogify.ReadersTest do
  use Blogify.DataCase

  alias Blogify.Readers

  describe "readers" do
    alias Blogify.Readers.Reader

    import Blogify.ReadersFixtures

    @invalid_attrs %{name: nil, email: nil}

    test "list_readers/0 returns all readers" do
      reader = reader_fixture()
      assert Readers.list_readers() == [reader]
    end

    test "get_reader!/1 returns the reader with given id" do
      reader = reader_fixture()
      assert Readers.get_reader!(reader.id) == reader
    end

    test "create_reader/1 with valid data creates a reader" do
      valid_attrs = %{name: "some name", email: "some email"}

      assert {:ok, %Reader{} = reader} = Readers.create_reader(valid_attrs)
      assert reader.name == "some name"
      assert reader.email == "some email"
    end

    test "create_reader/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Readers.create_reader(@invalid_attrs)
    end

    test "update_reader/2 with valid data updates the reader" do
      reader = reader_fixture()
      update_attrs = %{name: "some updated name", email: "some updated email"}

      assert {:ok, %Reader{} = reader} = Readers.update_reader(reader, update_attrs)
      assert reader.name == "some updated name"
      assert reader.email == "some updated email"
    end

    test "update_reader/2 with invalid data returns error changeset" do
      reader = reader_fixture()
      assert {:error, %Ecto.Changeset{}} = Readers.update_reader(reader, @invalid_attrs)
      assert reader == Readers.get_reader!(reader.id)
    end

    test "delete_reader/1 deletes the reader" do
      reader = reader_fixture()
      assert {:ok, %Reader{}} = Readers.delete_reader(reader)
      assert_raise Ecto.NoResultsError, fn -> Readers.get_reader!(reader.id) end
    end

    test "change_reader/1 returns a reader changeset" do
      reader = reader_fixture()
      assert %Ecto.Changeset{} = Readers.change_reader(reader)
    end
  end
end
