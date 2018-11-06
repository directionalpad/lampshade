defmodule Lampshade.SunlightApi do
  alias Lampshade.Logger

  def fetch_sunlight(latitude, longitude) do
    case HTTPoison.get("https://api.sunrise-sunset.org/json?lat=#{latitude}&lng=#{longitude}&date=today&formatted=0") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, 
          Poison.decode!(body) 
          |> Map.get("results") 
          |> Map.put("retrieved", DateTime.utc_now())
        }
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Failed to fetch sunset and sunrise details. Reason: #{reason}."}
    end
  end
end