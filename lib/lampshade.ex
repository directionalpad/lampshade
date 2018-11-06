defmodule Lampshade do
  use Application
  import List
  alias Lampshade.Logger
  alias Huex

  def start(_type, _args) do
    Logger.debug "Locating Hue Bridge..."
    bridge = get_bridge()
    Logger.debug "Bridge located.\n#{inspect(bridge)}"

    Logger.info "Starting Lampshade."
    children = [ {Lampshade.TemperatureServer, %{:bridge => bridge, :sunlight => nil, :tracked_lights => []}} ]
    opts = [strategy: :one_for_one, name: Lampshade.Supervisor]
    list_groups(bridge)
    Supervisor.start_link(children, opts)
  end

  defp get_bridge() do
   case Application.get_env(:lampshade, :bridge_address) do
     nil -> 
      Logger.debug "No :bridge_address specified in config. Falling back to SSDP."
      discover_bridge()
     _ -> 
      Logger.debug "Using explicitly defined :bridge_address from config."
      Application.get_env(:lampshade, :bridge_address)
   end
   |> Huex.connect(Application.get_env(:lampshade, :username))
  end

  defp discover_bridge() do
    bridge = Huex.Discovery.discover()
    |> first

    case bridge do
      nil -> 
        Logger.error "Failed to locate Hue Bridge. Reattempting bridge discovery in 5 seconds. If you continue to see this error please see the README for more information."
        Process.sleep(5000)
        discover_bridge()
      _ -> bridge
    end
  end

  defp list_groups(bridge) do
    Logger.info "Listing Available Light Groups: "
    Enum.each(Huex.groups(bridge), fn {k,v} -> IO.puts IO.ANSI.light_green() <> "\t - " <> IO.ANSI.reset() <> "#{v["name"]}" <> IO.ANSI.reset() end)
    IO.puts "\n"
  end
end
