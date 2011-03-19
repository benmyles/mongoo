if ENV["ASYNC"] == "1" || (ENV["SYNC"] != "1" && (defined?(EM) && EM.reactor_running?))
  require "em-synchrony"
  require "em-synchrony/tcpsocket"
  module Mongo
    class Connection
      EMTCPSocket = ::EventMachine::Synchrony::TCPSocket

      def check_is_master(node)
        begin
          host, port = *node
          socket = EMTCPSocket.new(host, port)
          socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

          config = self['admin'].command({:ismaster => 1}, :socket => socket)
        rescue OperationFailure, SocketError, SystemCallError, IOError => ex
          close
        ensure
          socket.close if socket
        end

        config
      end
    end
  end

  if defined?(RAILS_DEFAULT_LOGGER)
    RAILS_DEFAULT_LOGGER.info "* Mongoo Running in Asynchronous Mode"
  else
    puts "* Mongoo Running in Asynchronous Mode"
  end
else
  if defined?(RAILS_DEFAULT_LOGGER)
    RAILS_DEFAULT_LOGGER.info "* Mongoo Running in Synchronous Mode"
  else
    puts "* Mongoo Running in Synchronous Mode"
  end
end