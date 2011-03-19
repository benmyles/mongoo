if ENV["MONGOO_ASYNC"] == "1" || (ENV["MONGOO_SYNC"] != "1" && (defined?(EM) && EM.reactor_running?))
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

  puts "* Mongoo Running in Asynchronous Mode" if ENV["MONGOO_DEBUG"] == "1"
else
  module Mongoo
    def self.mode
      :sync
    end
  end
  
  puts "* Mongoo Running in Synchronous Mode" if ENV["MONGOO_DEBUG"] == "1"
end