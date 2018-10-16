defmodule Ueberauth.Strategy.Ecwid do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Ecwid.

  ### Setup

  Create an application in Ecwid for you to use.

  Register a new application at the [ecwid developers page](https://developers.ecwid.com/) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          ecwid: { Ueberauth.Strategy.Ecwid, [] }
        ]

  Then include the configuration for ecwid.

      config :ueberauth, Ueberauth.Strategy.Ecwid.OAuth,
        client_id: System.get_env("ECWID_API_KEY"),
        client_secret: System.get_env("ECWID_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          ecwid: { Ueberauth.Strategy.Ecwid, [default_scope: "read_store_profile,read_catalog,read_orders,read_customers"] }
        ]

  Default is "read_store_profile"
  """

  use Ueberauth.Strategy,
    uid_field: :store_id,
    default_scope: "read_store_profile"

  alias Ueberauth.Auth.Credentials

  @doc """
  Handles the initial redirect to the Ecwid authentication page.

  To customize the scope (permissions) that are requested by ewcid include them as part of your url:

      "https://my.ecwid.com/api/oauth/authorize?store_id={store_id}&scope=read_store_profile"

  You can also include a `state` param that ecwid will return to you.
  """
  def handle_request!(%Plug.Conn{} = conn) do
    opts = get_options(conn)
    redirect!(conn, Ueberauth.Strategy.Ecwid.OAuth.authorize_url!(opts))
  end

  @doc """
  Handles the callback from Ecwid. When there is a failure from Ecwid the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Ecwid is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    token = Ueberauth.Strategy.Ecwid.OAuth.get_token!(code: code)

    if token.access_token == nil do
      err = token.other_params["error"]
      desc = token.other_params["error_description"]
      set_errors!(conn, [error(err, desc)])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code or shop received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Ecwid response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:ecwid_token, nil)
    |> put_private(:ecwid_user, nil)
  end

  @doc """
  Fetches the uid field from the Ecwid response. This defaults to the option `uid_field` which in-turn defaults to `store_id`
  """
  def uid(conn) do
    conn.private.ecwid_token.other_params["store_id"]
  end

  @doc """
  Includes the credentials from the Ecwid response.
  """
  def credentials(conn) do
    token = conn.private.ecwid_token
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, " ")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :ecwid_token, token)

    case Ueberauth.Strategy.Ecwid.OAuth.get(conn, token) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        put_private(conn, :ecwid_user, user)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp get_options(conn) do
    [
      scope: conn.params["scope"] || option(conn, :default_scope),
      redirect_uri: callback_url(conn),
      state: conn.params["state"],
      store_id: conn.params["store_id"]
    ]
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
