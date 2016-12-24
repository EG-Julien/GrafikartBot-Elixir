defmodule Discordbot.Code do
  
  alias DiscordEx.RestClient.Resources.Channel
  alias Discordbot.Helpers.Message

  def handle(:message_create, payload, state = %{rest_client: conn}) do
    if is_code(payload["content"]) do
      spawn fn ->
        Channel.delete_message(conn, payload["channel_id"], payload["id"])
      end
      spawn fn ->
        case Message.dm(conn, payload["author"]["id"], dm(payload)) do
          %{"code" => _code} ->
            Channel.send_message(conn, payload["channel_id"], %{content: message(payload)})
          _ -> 
            nil
        end
      end
    end
    {:ok, state}
  end

  def handle(_type, _payload, state) do
    {:ok, state}
  end 
  
  @doc """
  Is this message is code ?
  """
  def is_code(message) do
    if Kernel.length(String.split(message, "\n")) > 7 do
      Regex.scan(~r/[\{\}\[\]$;]/m, message)
        |> Kernel.length
        >= 3
    else
      false
    end
  end

  @doc """
  Message to send if code is detected
  """
  def message(payload) do
    link = case Hastebin.send(payload["content"]) do
      {:ok, link} -> link
      _ -> ""
    end
    Application.get_env(:discordbot, :code)[:message]
      |> String.replace("@user", Message.mention(payload))
      |> String.replace("@link", link)
  end

  @doc """
  Private message to send if code is detected
  """
  def dm(payload) do
    Application.get_env(:discordbot, :code)[:dm]
      |> String.replace("@code", payload["content"])
  end

end
