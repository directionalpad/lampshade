use Mix.Config

config :lampshade,

  # Phillips Hue Bridge Username
  # The username provided is merely an example. You will need to get a randomly generated username for Hue Bridge
  # in order to allow Lampshade to control your lights. 
  # See https://developers.meethue.com/documentation/getting-started on how to get your Phillips Hue Bridge username.
  username: "TX1B1eTc04PTN4ngbTYYYzQePnzHIpQ13511X3CP",

  # Phillips Hue Bridge IP Address
  # This parameter can be used to explicitly set your Hue Bridge IP address if you have more than one bridge
  # or if SSDP fails to locate the bridge. Removal of this file from the configuration file will result in 
  # Lampshade falling back to SSDP to locate your Hue Bridge.
  bridge_address: "192.168.0.103",

  # Temperature Light Groups
  # This is a collection of light group names that you want Lampshade to monitor and adjust throughout the day.
  # These are the group or room names that you configure lights on within the Hue App. Lampshade will also
  # provide a list of all light group names when started as a convenient way to locate the light groups
  # you want Lampshade to work with.
  temperature_light_groups: ["My Bedroom", "Hallway", "Living Room"],

  # Color Temperature
  # Hue lights have a color temperature range of 2000K (warm/yellow light) to 6500K (bright/white light).
  # Only some Hue types of Hue lights support having their color temperature set. Lampshade will only adjust
  # the color temperature of lights that support the color temperature light mode. If you find the lights are
  # getting to yellow or white for your tastes feel free to play with these settings.
  # CAUTION:
  # minimum_temperature cannot be less than 2200
  # maximum_temperature cannot be more than 6500
  minimum_temperature: 3100,
  maximum_temperature: 6500,

  # Light Brightness 
  # Hue lights have a possible brightness range of 0-254 where the higher the number the brighter the light.
  # If you find that the lights are getting too bright or dim for your tastes feel free to play with these settings.
  # CAUTION: 
  # minimum_brightness cannot be less than 0. 
  # maximum_brightness cannot be more than 254.
  minimum_brightness: 140,    
  maximum_brightness: 254,

  # Latitude and Longitude for your location.
  # Location details are needed to grab the correct sunset, sunrise, and solar noon times for your area.
  # You can look up your Latitude and Longitude at https://sunrise-sunset.org/ by entering your zipcode.
  latitude: 27.9881,
  longitude: 86.9250,
  
  # Debug Mode. 
  # Leave this set to false unless you are experiencing problems and want to take a look at the debug log output.
  debug: false
