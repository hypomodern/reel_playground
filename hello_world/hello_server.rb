require 'rubygems'
require 'bundler/setup'
require 'reel'

class HelloServer < Reel::Server

  def initialize(host = "127.0.0.1", port = 1234)
    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    connection.respond :ok, "hello, world!\n"
  end
end

if ($0 === __FILE__)
  puts "Starting Hello Server on 127.0.0.1:1234"
  HelloServer.supervise_as :hello_world

  sleep
end