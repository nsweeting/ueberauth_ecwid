defmodule Ueberauth.Strategy.Ecwid.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Ecwid.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.Ecwid.OAuth,
        client_id: System.get_env("ECWID_API_KEY"),
        client_secret: System.get_env("ECWID_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://my.ecwid.com",
    authorize_url: "https://my.ecwid.com/api/oauth/authorize",
    token_url: "https://my.ecwid.com/api/oauth/token"
  ]

  @doc """
  Construct a client for requests to Ecwid using configuration from Application.get_env/2

      Ueberauth.Strategy.Ecwid.OAuth.client(redirect_uri: "http://localhost:4000/auth/ecwid/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.Ecwid`.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.Ecwid.OAuth)
      |> check_config_key_exists(:client_id)
      |> check_config_key_exists(:client_secret)

    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(client_opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(_conn, token) do
    store_id = token.other["store_id"]
    access_token = token.access_token
    profile_url = "https://app.ecwid.com/api/v3/#{store_id}/profile?token=#{access_token}"

    OAuth2.Client.get(client(), profile_url)
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.Ecwid"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Ecwid is not a keyword list, as expected"
  end
end
