defmodule Lampshade.Logger do
  def debug(message) do

    if(Application.get_env(:lampshade, :debug)) do
      IO.puts IO.ANSI.light_cyan <> "#{DateTime.utc_now()} [DBG] #{message}" <> IO.ANSI.reset()
    end
  end

  def error(message) do
    IO.puts IO.ANSI.light_red <> "#{DateTime.utc_now()} [ERR] #{message}" <> IO.ANSI.reset()
  end

  def info(message) do
    IO.puts IO.ANSI.light_green() <> "#{DateTime.utc_now()} [INF] #{message}" <> IO.ANSI.reset()
  end
end