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

  module Mongoo
    def self.mode
      :async
    end
  end

  if defined?(::Rails)
    ::Rails.logger.info "* Mongoo Running in Asynchronous Mode"
  else
    puts "* Mongoo Running in Asynchronous Mode" if ENV["DEBUG"] == "1"
  end
else
  module Mongoo
    def self.mode
      :sync
    end
  end
  
  if defined?(::Rails)
    ::Rails.logger.info "* Mongoo Running in Synchronous Mode"
  else
    puts "* Mongoo Running in Synchronous Mode" if ENV["DEBUG"] == "1"
  end
end