defmodule Exchat.ChatChannel do
  use Exchat.Web, :channel

  def join("rooms:lobby", payload, socket) do
    if authorized?(payload) do
      send(self, :join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:join, socket) do
    user = get_user(socket.assigns.uid)
    broadcast_from! socket, "users", %{users: [user]}
    push socket, "self", user
    push socket, "users", %{users: all_users}
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("self", %{"uid" => uid} = user, socket) do
    new_self = update_user(uid, user)
    push socket, "self", new_self
    broadcast socket, "users", %{users: [new_self]}
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (rooms:lobby).
  def handle_in("say", %{"msg" => msg}, socket) do
    broadcast socket, "say", %{uid: socket.assigns.uid, msg: msg}
    {:noreply, socket}
  end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  def terminate({:shutdown, reason} = event, socket) do
    broadcast_from socket, "users", %{users: [delete_user(socket.assigns.uid)]}
    event
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp get_user(uid) do
    case :ets.lookup(:online_users, uid) do
      [] ->
        user = %{uid: uid, name: "user_#{uid}", on: true}
        true = :ets.insert :online_users, {uid, user}
        user
      [{_uid, user}] -> %{user | on: true}
    end
  end

  defp delete_user(uid) do
    [{uid, user}] = :ets.lookup :online_users, uid
    true = :ets.delete(:online_users, uid)
    %{user | on: false}
  end

  defp update_user(uid, user) do
    true = :ets.update_element :online_users, uid, {2, user}
    user
  end

  defp all_users do
    :online_users
    |> :ets.tab2list
    |> Keyword.values
  end
end
