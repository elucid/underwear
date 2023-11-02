defmodule UnderworkWeb.SetupLive do
  use UnderworkWeb, :live_view

  alias Underwork.Cycles

  def mount(_params, _session, socket) do
    session = Cycles.current_session_for_user()
    changeset = Cycles.change_session_cycles(session)

    socket =
    socket
    |> assign(:session, session)
    |> assign(:target_cycles, session.target_cycles)
    |> assign_form(changeset)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <:subtitle>Use this form to manage session records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="session-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:start_at]} type="datetime-local" label="Start at" />
        <div>
          <label>Cycles</label>
          <.button type="button" phx-click="decrement_cycles" phx-disable={@target_cycles == 2}>-</.button>
          <span><%= @target_cycles %></span>
          <.button type="button" phx-click="increment_cycles" phx-disable={@target_cycles == 18}>+</.button>
          <.input field={@form[:target_cycles]} value={@target_cycles} type="hidden" />
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Session</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", %{"session" => session_params}, socket) do
    changeset =
      socket.assigns.session
      |> Cycles.change_session_cycles(session_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("increment_cycles", _, socket) do
    socket =
    socket
    |> update(:target_cycles, fn cycles -> min(cycles + 1, 18) end)

    {:noreply, socket}
  end

  def handle_event("decrement_cycles", _, socket) do
    socket =
    socket
    |> update(:target_cycles, fn cycles -> max(cycles - 1, 2) end)

    {:noreply, socket}
  end

  def handle_event("save", %{"session" => session_params}, socket) do
    case Cycles.configure_session(socket.assigns.session, session_params) do
      {:ok, session} ->

        {:noreply,
         socket
         |> put_flash(:info, "Session updated successfully")
         |> push_navigate(to: ~p"/cycles")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
