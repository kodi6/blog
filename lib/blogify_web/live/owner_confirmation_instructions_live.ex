defmodule BlogifyWeb.OwnerConfirmationInstructionsLive do
  use BlogifyWeb, :live_view

  alias Blogify.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        No confirmation instructions received?
        <:subtitle>We'll send a new confirmation link to your inbox</:subtitle>
      </.header>

      <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Resend confirmation instructions
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4">
        <.link href={~p"/owners/register"}>Register</.link>
        | <.link href={~p"/owners/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "owner"))}
  end

  def handle_event("send_instructions", %{"owner" => %{"email" => email}}, socket) do
    if owner = Accounts.get_owner_by_email(email) do
      Accounts.deliver_owner_confirmation_instructions(
        owner,
        &url(~p"/owners/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
