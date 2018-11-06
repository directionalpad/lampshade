use Mix.Config

config :lampshade,
  username: "",
  bridge_address: "",    # Optional, will fall back to SSDP if this parameter is removed from the configuration file
  debug: false,
  temperature_light_groups: [],
  minimum_temperature: 3100,
  maximum_temperature: 6500,
  minimum_brightness: 140,
  maximum_brightness: 254,
  latitude: 27.9881,
  longitude: 86.9250

