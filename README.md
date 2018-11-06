# Lampshade

Lampshade is a home automation service written in Elixir responsible for controlling the color temperature and brightness of Phillips Hue lights throughout the day. Lights configured to use Lampshade will start at a specified color temperature and/or brightness and gradually increase through the day until solar noon. At solar noon the lights will reach the highest configured color temperature and start to decline back down to the temperature and/or brightness settings (see "How to Configure Lampshade" for mode details). Lampshade uses the [Sunrise Sunset API](https://sunrise-sunset.org/api) to determine sunrise, sunset, and solar noon for a given location.

## Requirements

- Elixir 1.6.x (will work on 1.7.x)

## Installation

Installation assumes you have an Elixir 1.6.x environment setup on the machine where Lampshade will be running and a git client available for checking out the repository. You will need to configure Lampshade before running it. Please see the **How to Configure Lampshade** section below for more information.

You can install Lampshade by executing the following commands:

```
# git clone https://github.com/directionalpad/lampshade
# cd lampshade/
# mix deps.get
```

After Lampshade has been cloned and it's dependencies have been installed you should configure Lampshade's configuration file located at [config/config.exs](config/config.exs) before running it. Once Lampshade has been configured you can run the application by running the following command from the directory where you checked out the Lampshade repository:

```
iex -S mix
```

## How to Configure Lampshade

_If you are already familiar with Hue Bridge concepts or need further clarification there is an annotated sample configuration file provided in [config/sample.exs](config/sample.exs)._


#### Phillips Hue Bridge Preparation

In order for Lampshade to be able to control your lights you will need to acquire the ip address and a username from your Phillips Hue Bridge. 

You can get details on the official Hue developer site on how to retrieve both pieces of information from their [Getting Started Guide](https://developers.meethue.com/documentation/getting-started)


#### Lampshade Configuration

Lampshade comes with a configuration file located at [config/config.exs](config/config.exs). 

```
use Mix.Config

config :lampshade,
  username: "",
  bridge_address: "",   
  temperature_light_groups: [],
  minimum_temperature: 3100,
  maximum_temperature: 6500,
  minimum_brightness: 140,
  maximum_brightness: 254,
  latitude: 27.9881,
  longitude: 86.9250,
  debug: false
```

Some values in the configuration file come already preset for convenience. These values can be adjusted to your specific preference. More information on those fields can be found in the annotated sample configuration file mentioned at the top of this section.

Five configuration values need to be set or changed before running Lampshade for the first time. These values are `username`, `bridge_address`, `temperature_light_groups`, `latitude`, and `longitude`.

`username` should be set to your Hue Bridge Username that you retrieved from the **Phillips Hue Bridge Prepration** section above.

_Example `username` configuration_
```
  username: "TX1B1eTc04PTN4ngbTYYYzQePnzHIpQ13511X3CP",
```

`bridge_address` should be set to your Hue Bridge ip address that you retrieved from the **Phillips Hub Bridge Preparation** section above. This parameter can also optionally be removed entirely from the configuration file entirely. Doing so wil cause Lampshade to fall back to SSDP meaning it will attempt to self-discover the bridge on its own. If you decide to use SSDP you may need to push the button on your bridge the first time Lampshade attempts to find it. Follow-up runs of Lampshade should discover the bridge on its own.

_Example `bridge_address` configuration_
```
 bridge_address: "192.168.0.103",
 ```

`temperature_light_groups` is a collection of light groups that you want Lampshade to monitor and adjust throughout the day. The names of the groups are the same as "room names" that you add lights to within the Hue App. Lampshade will also rpovide you with a list of all light group names that belong to the corresponding bridge when you start the application.

_Example `temperature_light_groups` configuration_
```
 temperature_light_groups: ["My Bedroom", "Hallway", "Living Room"],
```

`latitude` and `longitude` should be set to your location. By default they are set to the coordinates of Mount Everest. Lampshade needs these values in order to determine the correct sunset, sunrise, and solar noon times for your area. Without this information Lampshade will not be able to keep your light's brightness and color temperatures correct for the current time of day at your location. You can retrieve your latitude and longitude information by visiting [https://sunrise-sunset.org/](https://sunrise-sunset.org/) and entering your postal code in the search box on the site. 

_Example `latitude` and `longitude` configuration_
```
  latitude: 27.9881,
  longitude: 86.9250,
```

## Attributions
Sunrise Sunset - [https://sunrise-sunset.org/](https://sunrise-sunset.org/)


## License
Lampshade is released under the [BSD 3-Clause License](LICENSE). 