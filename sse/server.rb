require 'rubygems'
require 'bundler/setup'
require 'reel'
require 'sse/sse'

class WebServer < Reel::Server
  include Celluloid::Logger

  ASSET_PATH = File.join(File.dirname(__FILE__), "..", "ui", "dist")

  def initialize(host = "127.0.0.1", port = 3000)
    info "SSE example starting on #{host}:#{port}"
    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    while request = connection.request
      info "Client requested: #{request.method} #{request.url} #{request.query_string}"

      # "routing"
      case request.url
      when "/"
        render_index(connection)
      when "/time"
        stream!(connection)
      else
        render_asset(connection, request.url)
      end

      info "Finished handling connection"
    end
  end

  def stream(connection)
    connection.detach

    headers = {'Content-Type' => 'text/event-stream', 'Transfer-Encoding' => 'chunked'}

    connection.respond(:ok, headers)

    sse = SSE.new(connection)

    begin
      now = Time.now.to_f
      sleep now.ceil - now + 0.001

      loop do
        info "Returning current-time: #{Time.now}"
        sse.write({:time => Time.now}, :event => 'current-time')
        sleep 1
      end
    rescue IOError, Errno::EPIPE, Errno::ECONNRESET
    ensure
      info "Closing SSE"
      sse.close
    end
  end

  def render_not_found(connection, url = "/")
    message = "404 Not Found: #{url}"
    info message
    connection.respond :not_found, message
  end

  # blocking I/O in my non-blocking server? it's more likely than you think!
  def render_asset(connection, url)
    asset_path = File.join(ASSET_PATH, url)
    if File.exist?(asset_path)
      info "200 OK: #{url}"
      asset = File.read(asset_path)
      connection.respond(:ok, asset)
    else
      render_not_found(connection, url)
    end
  end

  def render_index(connection)
    render_asset(connection, "index.html")
  end
end

WebServer.supervise_as :reel

sleep