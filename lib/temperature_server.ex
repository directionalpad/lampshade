defmodule Lampshade.TemperatureServer do
  use GenServer
  alias Lampshade.{Logger, SunlightApi}
  alias Huex

  def start_link(state) do
    Logger.debug "Initializing Light Temperature Control..."
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Logger.info "Light Temperature Control Started."
    state = %{state | sunlight: update_sunlight_information()}
    schedule_work()
    {:ok, state}
  end
  
  def handle_info(:poll, %{:bridge => bridge, :sunlight => sunlight} = state) do
    Logger.debug ":poll, #{inspect(state)}"
    Logger.debug "Polling Lights..."

    calculate_light_values(sunlight) 
    |> update_light_groups(bridge)

    schedule_lights()
    Logger.debug "Light polling complete."
    {:noreply, state}
  end

  def handle_info(:sunlight, state) do
    Logger.debug ":sunlight, #{inspect(state)}"
    Logger.debug "Updating daylight information..."
    state = %{state | sunlight: update_sunlight_information()}
    schedule_sunlight()
    Logger.debug "Daylight information update complete."
    {:noreply, state}
  end

  def handle_info(:discover_lights, state) do
    Logger.debug ":discover_lights, #{inspect(state)}"
    Logger.debug "Scanning for newly turned on light groups"
    {:ok, tracked_lights} = discover_lights(state)
    schedule_light_tracker()
    Logger.debug "Currently tracked light groups: #{inspect(tracked_lights)}"
    {:noreply, %{state | tracked_lights: tracked_lights}}
  end

  defp calculate_light_values(sunlight) do
    {:ok, solar_noon, _offset} = DateTime.from_iso8601(sunlight["solar_noon"])

    case is_morning?(solar_noon) do
      true ->
        DateTime.from_iso8601(sunlight["sunrise"])
      false -> 
        DateTime.from_iso8601(sunlight["sunset"])
    end
    |> elem(1)   
    |> calculate_step(solar_noon)
    |> calculate_current_light_values
  end

  defp is_morning?(solar_noon) do
    if (DateTime.diff(DateTime.utc_now, solar_noon) < 0), do: true, else: false
  end

  defp calculate_step(period_start, solar_noon) do
    # Calculates the brightness step and light temperature step up or step down 
    # (in Kelvin) per minute for a given day period (morning or afternoon)

    temperature_step = 
      calculate_step_value(Application.get_env(:lampshade, :maximum_temperature), Application.get_env(:lampshade, :minimum_temperature), period_start, solar_noon)
    Logger.debug "Temperature Step is #{temperature_step} Kelvin per minute."

    brightness_step = 
     calculate_step_value(Application.get_env(:lampshade, :maximum_brightness), Application.get_env(:lampshade, :minimum_brightness), period_start, solar_noon)
    Logger.debug "Brightness step is #{brightness_step} per minute."

    {:ok, brightness_step, temperature_step, period_start}
  end
  
  defp calculate_step_value(maximum_value, minimum_value, period_start, solar_noon) do
    difference = maximum_value - minimum_value
    half_day_duration = DateTime.diff(solar_noon, period_start) / 60
    difference / half_day_duration
  end

  defp calculate_current_light_values({:ok, brightness_step, temperature_step, period_start}) do
    minimum_temperature = Application.get_env(:lampshade, :minimum_temperature)
    maximum_temperature = Application.get_env(:lampshade, :maximum_temperature)

    temperature =
      case calculate_current_value(minimum_temperature, period_start, temperature_step) do
        temperature when temperature > maximum_temperature ->
          maximum_temperature
        temperature when temperature < minimum_temperature ->
          minimum_temperature
        temperature -> temperature
      end
      |> convert_kelvin_to_mirek
    Logger.debug "Current converted temperature is #{temperature}."

    minimum_brightness = Application.get_env(:lampshade, :minimum_brightness)
    maximum_brightness = Application.get_env(:lampshade, :maximum_brightness)

    brightness = 
      case calculate_current_value(Application.get_env(:lampshade, :minimum_brightness), period_start, brightness_step) do
        brightness when brightness > maximum_brightness ->
          maximum_brightness
        brightness when brightness < minimum_brightness ->
          minimum_brightness
        brightness -> brightness
      end      
      |> trunc
      
    Logger.debug "Current brightness value is #{brightness}."

    {:ok, %{:temperature => temperature, :brightness => brightness}}
  end

  defp calculate_current_value(minimum_value, period_start, step) do
    difference = step * (DateTime.diff(DateTime.utc_now, period_start) / 60)
    minimum_value + difference
  end

  defp convert_kelvin_to_mirek(temperature) do
    trunc(1000000 / temperature)
  end

  defp schedule_work() do
    schedule_lights()
    schedule_light_tracker()
    schedule_sunlight()
  end

  defp schedule_lights() do
    Process.send_after(self(), :poll, 5 * 60 * 1000)
  end

  defp schedule_sunlight() do
    Process.send_after(self(), :sunlight, 4 * 60 * 60 * 1000)
  end

  defp schedule_light_tracker() do
    Process.send_after(self(), :discover_lights, 10 * 1000)
  end

  defp update_sunlight_information() do
    Logger.debug "Fetching sunlight details..."

    case SunlightApi.fetch_sunlight(
      Application.get_env(:lampshade, :latitude),
      Application.get_env(:lampshade, :longitude)
    ) do
        {:ok, sunlight} -> 
          Logger.debug "Sunlight details retrieved.\n#{inspect(sunlight)}"
          sunlight
        {:error, reason} -> 
          Logger.error "Failed to fetch sunlight details. Failure reason: #{reason}. Retrying in 15 seconds."
          # TODO: Have this use Process.send_after() to avoid blocking the process.
          Process.sleep(15 * 1000)    
          update_sunlight_information()
      end
  end

  defp update_light_groups({:ok, light_values}, bridge) do
    case Huex.groups(bridge) do
      {:error, reason} -> 
        Logger.error "Hue Bridge refused the connection from Lampshade (reason: #{reason})."
      result ->  
        Enum.filter(result, fn {_k,v} -> Enum.member?(Application.get_env(:lampshade, :temperature_light_groups),v["name"]) end)
        |> Enum.map(fn {_group_id, group_info} -> Enum.each(group_info["lights"], fn light -> set_light_state(group_info, light, light_values, bridge) end) end)
    end
  end

  defp discover_lights(%{:tracked_lights => tracked_lights, :sunlight => sunlight, :bridge => bridge}) do
    tracked_lights =
      case Huex.groups(bridge) do
        {:error, reason} -> 
          Logger.error "Hue bridge refused the connection from Lampshade (reason: #{reason})."
          []
        result ->
          untracked_lights = 
            Enum.filter(result, 
              fn {_group_id, group_info} -> 
                Enum.member?(Application.get_env(:lampshade, :temperature_light_groups), group_info["name"]) && 
                group_info["state"]["all_on"] == true 
              end)

          Enum.reject(untracked_lights, fn {_group_id, group_info} -> Enum.member?(tracked_lights, group_info["name"]) end)
          |> Enum.map(
            fn {_group_id, group_info} -> 
              {:ok, light_values} = calculate_light_values(sunlight)
              Logger.debug "Updating temperature values for newly discovered light group #{group_info["name"]}."
              Enum.each(group_info["lights"],
                fn light ->
                  set_light_state(group_info, light, light_values, bridge)
                end)
            end)         
          
          Enum.map(untracked_lights, fn {_group_id, group_info} -> group_info["name"] end)
      end
    {:ok, tracked_lights}
  end

  defp set_light_state(%{"state" => %{"all_on" => true}} = group_info, light, light_values, bridge) do
   light_info = Huex.light_info(bridge, light)

   if(light_info["state"]["reachable"]) do
    map =
      cond do
        light_info["state"]["bri"] && light_info["state"]["ct"] ->
          %{"bri" => light_values[:brightness], "ct" => light_values[:temperature]}
        light_info["state"]["bri"] ->
          %{"bri" => light_values[:brightness]}
        light_info["state"]["ct"] ->
          %{"ct" => light_values[:temperature]}
        true -> 
          nil
      end

    if(!is_nil(map)) do
      Huex.set_state(bridge, light, map)
      Logger.info "Light ID #{light}'s (group: #{group_info["name"]}) temperature and brightness have been updated with values #{inspect(map)}"
     end
   end
  end

  defp set_light_state(group_info, _light, _light_values, _bridge) do
    Logger.debug "Light group #{group_info["name"]} must have all lights in group turned on."
  end
end