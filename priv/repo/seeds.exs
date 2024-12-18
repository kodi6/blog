# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Blogify.Repo.insert!(%Blogify.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.



# Assume this is in some module or script where you want to insert dummy data

# Create multiple instances of the post struct with different data
posts_data = [
  %Blogify.Posts.Post{
    title: "Post 1",
    description: "Description for Post 1",
    markup_text: "This is some sample text for Post 1."
  },
  %Blogify.Posts.Post{
    title: "Post 2",
    description: "Description for Post 2",
    markup_text: "This is some sample text for Post 2."

  },
  %Blogify.Posts.Post{
    title: "Post 3",
    description: "Description for Post 3",
    markup_text: "This is some sample text for Post 3."
  },
  %Blogify.Posts.Post{
    title: "Post 4",
    description: "Description for Post 4",
    markup_text: "This is some sample text for Post 4."
  },
  %Blogify.Posts.Post{
    title: "Post 5",
    description: "Description for Post 5",
    markup_text: "This is some sample text for Post 5."}
]

# Insert each post into the database
Enum.each(posts_data, fn post ->
  Blogify.Repo.insert(post)
end)




Blogify.Repo.insert!( %Blogify.Posts.Post{
  title: "Post 1",
  description: "Description for Post 1",
  markup_text: "This is some sample text for Post 1."
})

Blogify.Repo.insert!( %Blogify.Posts.Post{
  title: "Post 2",
  description: "Description for Post 2",
  markup_text: "This is some sample text for Post 1."
})

Blogify.Repo.insert!( %Blogify.Posts.Post{
  title: "Post 3",
  description: "Description for Post 3",
  markup_text: "This is some sample text for Post 1."
})


Blogify.Repo.insert!( %Blogify.Posts.Post{
  title: "Post 4",
  description: "Description for Post 4",
  markup_text: "This is some sample text for Post 4."
})


Blogify.Repo.insert!( %Blogify.Posts.Post{
  title: "Post 5",
  description: "Description for Post 5",
  markup_text: "This is some sample text for Post 1."
})
