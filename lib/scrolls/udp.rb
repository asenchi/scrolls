require 'socket'

module Scrolls
  class UDPLogger

    def initialize(host, port, options={})
      @host = host || "127.0.0.1"
      @port = port || "514"

      initialize_socket
    end

    def initialize_socket
      @socket = UDPSocket.new
      @socket.connect(@host, @port)
    end

    def socket
      @socket ||= initialize_socket
    end

    def puts(data)
      socket.send(data, 0)
    end
  end
end
