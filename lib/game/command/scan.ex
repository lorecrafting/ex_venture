defmodule Game.Command.Scan do
  @moduledoc """
  The "scan" command
  """

  use Game.Command

  alias Game.Door
  alias Game.Format

  commands(["scan"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Scan"
  def help(:short), do: "Look around your surroundings"

  def help(:full) do
    """
    #{help(:short)}. Shows NPCs and players in the current and adjacent rooms.

    Example:
    [ ] > {command}scan{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Scan.parse("scan")
      {}

      iex> Game.Command.Scan.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("scan"), do: {}

  @impl Game.Command
  def run(command, state)

  def run({}, state = %{save: save}) do
    {:ok, room} = @environment.look(save.room_id)
    rooms = scan_rooms(room)
    state |> Socket.echo(Format.Scan.room(room, rooms))
  end

  defp scan_rooms(room) do
    room.exits
    |> Enum.map(&scan_room/1)
    |> Enum.reject(&room_empty?/1)
  end

  defp scan_room(room_exit) do
    case room_exit.has_door && Door.closed?(room_exit.door_id) do
      true ->
        {room_exit.direction, :closed}

      _ ->
        {:ok, room} = @environment.look(room_exit.finish_id)
        {room_exit.direction, room}
    end
  end

  defp room_empty?({_, :closed}), do: true

  defp room_empty?({_, room}) do
    Enum.empty?(room.npcs) && Enum.empty?(room.players)
  end
end
