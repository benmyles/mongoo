unless defined?(Mongo)
  raise "!! mongoo/async must be loaded AFTER mongo !!"
end

original_verbosity = $VERBOSE
$VERBOSE = nil

require 'em-synchrony'
require 'em-synchrony/tcpsocket'
require 'em-synchrony/thread'

module Mongo

  class Connection
    TCPSocket         = ::EventMachine::Synchrony::TCPSocket
    Mutex             = ::EventMachine::Synchrony::Thread::Mutex
    ConditionVariable = ::EventMachine::Synchrony::Thread::ConditionVariable
  end

  def self.async?
    true
  end

end


module Mongo
  class EMPool
    TCPSocket = ::EventMachine::Synchrony::TCPSocket

    attr_accessor :host, :port, :size, :timeout, :safe, :checked_out

    # Create a new pool of connections.
    #
    def initialize(connection, host, port, opts={})
      @connection  = connection
      @host, @port = host, port

      # # Pool size and timeout.
      # @size      = opts[:size]    || 1
      # @timeout   = opts[:timeout] || 5.0

      # # Operations to perform on a socket
      # @socket_ops = Hash.new { |h, k| h[k] = [] }

      # @all       = []
      # @reserved  = {}   # map of in-progress connections
      # @available = []   # pool of free connections
      # @pending   = []   # pending reservations (FIFO)

      # setup_pool!(host, port)
    end

    def setup_pool!(host, port)
      true
      # @size.times do |i|
      #   sock = checkout_new_socket(host, port)
      #   @all << sock
      #   @available << sock
      # end
    end

    def close
      true
      # @all.each do |sock|
      #   begin
      #     sock.close
      #   rescue IOError => ex
      #     warn "IOError when attempting to close socket connected to #{@host}:#{@port}: #{ex.inspect}"
      #   end
      # end
      # @host = @port = nil
      # @all.clear
      # @reserved.clear
      # @available.clear
      # @pending.clear
    end

    # Return a socket to the pool.
    def checkin(socket)
      socket.close
      # fiber = Fiber.current
      # @available.push(@reserved.delete(fiber.object_id))
      # if pending = @pending.shift
      #   pending.resume
      # end
      true
    end

    # If a user calls DB#authenticate, and several sockets exist,
    # then we need a way to apply the authentication on each socket.
    # So we store the apply_authentication method, and this will be
    # applied right before the next use of each socket.
    def authenticate_existing
      true
      # @all.each do |socket|
      #   @socket_ops[socket] << Proc.new do
      #     @connection.apply_saved_authentication(:socket => socket)
      #   end
      # end
    end

    # Store the logout op for each existing socket to be applied before
    # the next use of each socket.
    def logout_existing(db)
      true
      # @all.each do |socket|
      #   @socket_ops[socket] << Proc.new do
      #     @connection.db(db).issue_logout(:socket => socket)
      #   end
      # end
    end

    # Check out an existing socket or create a new socket if the maximum
    # pool size has not been exceeded. Otherwise, wait for the next
    # available socket.
    def checkout
      checkout_new_socket(@host, @port)
      # fiber = Fiber.current
      # #puts "[P: #{@pending.size}, A: #{@available.size}, ALL: #{@all.size}]"
      # if socket = @available.pop
      #   @reserved[fiber.object_id] = socket
      #   socket
      # else
      #   Fiber.yield @pending.push fiber
      #   checkout
      # end
    end

    # Adds a new socket to the pool and checks it out.
    #
    # This method is called exclusively from #checkout;
    # therefore, it runs within a mutex.
    def checkout_new_socket(host, port)
      # return nil if @all.size >= @size
      begin
        socket = TCPSocket.new(host, port)
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      rescue => ex
        raise ConnectionFailure, "Failed to connect to host #{@host} and port #{@port}: #{ex}"
      end

      # If any saved authentications exist, we want to apply those
      # when creating new sockets.
      @connection.apply_saved_authentication(:socket => socket)

      socket
    end; protected :checkout_new_socket
  end # EMPool
end # Mongo

Mongo::Pool = Mongo::EMPool

$VERBOSE = original_verbosity