# PlugWebhook

Simple tool for building plugs that handle wehbooks and verify signature.

As a design decision, this library, similar to Plug itself, does not
store the request body for a long time - the whole body is stored only
for the signature verification and parsing.

## Example

This is how a simple webhook router that verifies signature for
GithHub webhooks could look like:

```elixir
defmodule MyWebhookHandler do
  @behaviour Plug
  @behaviour PlugWebhook

  def init(opts), do: opts

  def verify_signature(conn, body, _opts) do
    token = ## get github token, e.g. System.get_env("GITHUB_TOKEN")
    signature = "sha1=" <> Base.encode16(:crypto.hmac(:sha, token, body))
    [verify_against] = get_req_header(conn, "x-hub-signature")
    if Plug.Crypto.secure_compare(signature, verify_against) do
      conn
    else
      conn
      |> send_resp(400, "bad signature")
      |> halt() # remeber to always halt if signature doesn't match
    end
  end

  def call(conn, opts) do
    json_body = conn.body_params
    IO.inspect({:got_json, json_body})
    send_resp(conn, 200, "")
  end
end
```

With such definition, we can add this handler into our application using:

```elixir
plug PlugWebhook, handler: MyWebhookHandler, parser_opts: ...
```

Where `:parser_opts` would be the options, you'd usually pass to `Plug.Parsers`.
It's important to add the `PlugWebhook` before parsers themselves.
For example, in a Phoenix application, this could look as (in the endpoint module):

```elixir
parser_opts = [
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library()
]

plug PlugWebhook,
  at: "/github_webhook",
  parser_opts: parser_opts,
  handler: MyWebhookHandler

plug Plug.Parsers, parser_opts
```

## Installation

The package can be installed by adding `plug_webhook` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plug_webhook, "~> 0.1.0"}
  ]
end
```

## License

This library is released under the Apache 2.0 License - see the [LICENSE](LICENSE) file.
