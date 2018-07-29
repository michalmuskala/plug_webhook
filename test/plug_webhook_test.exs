defmodule PlugWebhookTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule Sample do
    import Plug.Conn

    @behaviour Plug
    @behaviour PlugWebhook

    @impl true
    def verify_signature(conn, "x=good", _), do: conn

    def verify_signature(conn, "x=bad", _) do
      conn
      |> send_resp(400, "bad signature")
      |> halt()
    end

    @impl true
    def init(options), do: options

    @impl true
    def call(conn, _options) do
      send_resp(conn, 200, "hello")
    end
  end

  test "calls the plug" do
    conn = call(build_conn("/", "x=good"), Sample, [])
    assert {200, _, "hello"} = sent_resp(conn)
  end

  test "parses the body" do
    conn = call(build_conn("/", "x=good"), Sample, [])
    assert {200, _, "hello"} = sent_resp(conn)
    assert conn.body_params == %{"x" => "good"}
  end

  test "runs the verify signature function" do
    conn = call(build_conn("/", "x=bad"), Sample, [])
    assert {400, _, "bad signature"} = sent_resp(conn)
  end

  test "handles path correctly" do
    conn = call(build_conn("/foo/bar/baz", "x=good"), Sample, at: "foo/bar")
    assert {200, _, "hello"} = sent_resp(conn)
    assert conn.path_info == ["baz"]
    assert conn.script_name == ["foo", "bar"]
  end

  defp build_conn(path, body) do
    conn(:post, path, body)
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
  end

  defp call(conn, mod, opts) do
    opts = Keyword.put(opts, :handler, mod)
    opts = Keyword.put(opts, :parser_opts, parsers: [:urlencoded])
    PlugWebhook.call(conn, PlugWebhook.init(opts))
  end
end
