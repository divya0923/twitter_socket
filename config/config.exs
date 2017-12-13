# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :twitter_socket,
  ecto_repos: [TwitterSocket.Repo]

# Configures the endpoint
config :twitter_socket, TwitterSocket.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "D9H2zzfvmdBu2/3fMd52XSsR3CrgyhNizXv34kWeO+jVk3ueMDX7ot87C0AroiMq",
  render_errors: [view: TwitterSocket.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TwitterSocket.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
