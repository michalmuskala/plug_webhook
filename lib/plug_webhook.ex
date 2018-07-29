defmodule PlugWebhook do
  @moduledoc """
  Simple tool for building plugs that handle wehbooks and verify signature.

  As a design decision, this library, similar to Plug itself, does not
  store the request body for a long time - the whole body is stored only
  for the signature verification and parsing.

  ## Example

  This is how a simple webhook router that verifies signature for
  GithHub webhooks could look like:

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

  With such definition, we can add this handler into our application using:

      plug PlugWebhook, handler: MyWebhookHandler, parser_opts: ...

  Where `:parser_opts` would be the options, you'd usually pass to `Plug.Parsers`.
  It's important to add the `PlugWebhook` before parsers themselves.
  For example, in a Phoenix application, this could look as (in the endpoint module):

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

  """

  @type opts :: term()

  @callback verify_signature(Plug.Conn.t(), body :: String.t(), opts()) :: Plug.Conn.t()

  @behaviour Plug

  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    parser_opts = Keyword.fetch!(opts, :parser_opts)
    handler_opts = handler.init(opts)
    read_body = {__MODULE__, :__read_body__, [handler, handler_opts]}
    parser_opts = Keyword.put(parser_opts, :body_reader, read_body)
    at = Keyword.get(opts, :at, "")
    {split(at), Plug.Parsers.init(parser_opts), handler, handler_opts}
  end

  def call(%Plug.Conn{path_info: path, script_name: script} = conn, opts) do
    {at, parser_opts, handler, handler_opts} = opts

    case consume_prefix(path, at, []) do
      {base, left} ->
        conn = %{conn | path_info: left, script_name: script ++ base}

        case Plug.Parsers.call(conn, parser_opts) do
          %{halted: true} = conn -> conn
          conn -> handler.call(conn, handler_opts)
        end

      false ->
        conn
    end
  end

  defp consume_prefix([segment | path], [segment | at], acc) do
    consume_prefix(path, at, [segment | acc])
  end

  defp consume_prefix(path, [], acc), do: {:lists.reverse(acc), path}

  defp consume_prefix(_path, _at, _acc), do: false

  ## See Plug.Router.Utils.split/1
  defp split(bin) do
    for segment <- String.split(bin, "/"), segment != "", do: segment
  end

  @doc false
  def __read_body__(conn, opts, handler, handler_opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        {:ok, body, handler.verify_signature(conn, body, handler_opts)}

      other ->
        other
    end
  end
end
