# Überauth Ecwid

Ecwid OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Ecwid](https://developers.ecwid.com/).

2. Add `:ueberauth_ecwid` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_ecwid, "~> 0.1.1"}]
    end
    ```
    ```

3. Add Ecwid to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        ecwid: {Ueberauth.Strategy.Ecwid, []}
      ]
    ```

4.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Ecwid.OAuth,
      client_id: System.get_env("ECWID_API_KEY"),
      client_secret: System.get_env("ECWID_SECRET")
    ```

5.  If you haven't already, create a pipeline and setup routes for your callback handler:

    ```elixir
    pipeline :auth do
      Ueberauth.plug "/auth"
    end

    scope "/auth" do
      pipe_through [:browser, :auth]

      get "/:provider/callback", AuthController, :callback
    end
    ```

6.  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
        # do things with the failure
      end

      def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
        # do things with the auth
      end
    end
    ```

7. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/ecwid

Or with options:

    /auth/ecwid?store_id=1234567&scope=read_store_profile

By default the requested scope is "read_store_profile". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    ecwid: { Ueberauth.Strategy.Ecwid, [default_scope: "read_store_profile,read_catalog,read_orders,read_customers"] }
  ]
```
