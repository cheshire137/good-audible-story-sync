# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `net-http-persistent` gem.
# Please instead update this file by running `bin/tapioca gem net-http-persistent`.


# Persistent connections for Net::HTTP
#
# Net::HTTP::Persistent maintains persistent connections across all the
# servers you wish to talk to.  For each host:port you communicate with a
# single persistent connection is created.
#
# Connections will be shared across threads through a connection pool to
# increase reuse of connections.
#
# You can shut down any remaining HTTP connections when done by calling
# #shutdown.
#
# Example:
#
#   require 'net/http/persistent'
#
#   uri = URI 'http://example.com/awesome/web/service'
#
#   http = Net::HTTP::Persistent.new
#
#   # perform a GET
#   response = http.request uri
#
#   # or
#
#   get = Net::HTTP::Get.new uri.request_uri
#   response = http.request get
#
#   # create a POST
#   post_uri = uri + 'create'
#   post = Net::HTTP::Post.new post_uri.path
#   post.set_form_data 'some' => 'cool data'
#
#   # perform the POST, the URI is always required
#   response http.request post_uri, post
#
# Note that for GET, HEAD and other requests that do not have a body you want
# to use URI#request_uri not URI#path.  The request_uri contains the query
# params which are sent in the body for other requests.
#
# == TLS/SSL
#
# TLS connections are automatically created depending upon the scheme of the
# URI.  TLS connections are automatically verified against the default
# certificate store for your computer.  You can override this by changing
# verify_mode or by specifying an alternate cert_store.
#
# Here are the TLS settings, see the individual methods for documentation:
#
# #certificate        :: This client's certificate
# #ca_file            :: The certificate-authorities
# #ca_path            :: Directory with certificate-authorities
# #cert_store         :: An SSL certificate store
# #ciphers            :: List of SSl ciphers allowed
# #extra_chain_cert   :: Extra certificates to be added to the certificate chain
# #private_key        :: The client's SSL private key
# #reuse_ssl_sessions :: Reuse a previously opened SSL session for a new
#                        connection
# #ssl_timeout        :: Session lifetime
# #ssl_version        :: Which specific SSL version to use
# #verify_callback    :: For server certificate verification
# #verify_depth       :: Depth of certificate verification
# #verify_mode        :: How connections should be verified
# #verify_hostname    :: Use hostname verification for server certificate
#                        during the handshake
#
# == Proxies
#
# A proxy can be set through #proxy= or at initialization time by providing a
# second argument to ::new.  The proxy may be the URI of the proxy server or
# <code>:ENV</code> which will consult environment variables.
#
# See #proxy= and #proxy_from_env for details.
#
# == Headers
#
# Headers may be specified for use in every request.  #headers are appended to
# any headers on the request.  #override_headers replace existing headers on
# the request.
#
# The difference between the two can be seen in setting the User-Agent.  Using
# <code>http.headers['User-Agent'] = 'MyUserAgent'</code> will send "Ruby,
# MyUserAgent" while <code>http.override_headers['User-Agent'] =
# 'MyUserAgent'</code> will send "MyUserAgent".
#
# == Tuning
#
# === Segregation
#
# Each Net::HTTP::Persistent instance has its own pool of connections.  There
# is no sharing with other instances (as was true in earlier versions).
#
# === Idle Timeout
#
# If a connection hasn't been used for this number of seconds it will
# automatically be reset upon the next use to avoid attempting to send to a
# closed connection.  The default value is 5 seconds. nil means no timeout.
# Set through #idle_timeout.
#
# Reducing this value may help avoid the "too many connection resets" error
# when sending non-idempotent requests while increasing this value will cause
# fewer round-trips.
#
# === Read Timeout
#
# The amount of time allowed between reading two chunks from the socket.  Set
# through #read_timeout
#
# === Max Requests
#
# The number of requests that should be made before opening a new connection.
# Typically many keep-alive capable servers tune this to 100 or less, so the
# 101st request will fail with ECONNRESET. If unset (default), this value has
# no effect, if set, connections will be reset on the request after
# max_requests.
#
# === Open Timeout
#
# The amount of time to wait for a connection to be opened.  Set through
# #open_timeout.
#
# === Socket Options
#
# Socket options may be set on newly-created connections.  See #socket_options
# for details.
#
# === Connection Termination
#
# If you are done using the Net::HTTP::Persistent instance you may shut down
# all the connections in the current thread with #shutdown.  This is not
# recommended for normal use, it should only be used when it will be several
# minutes before you make another HTTP request.
#
# If you are using multiple threads, call #shutdown in each thread when the
# thread is done making requests.  If you don't call shutdown, that's OK.
# Ruby will automatically garbage collect and shutdown your HTTP connections
# when the thread terminates.
#
# source://net-http-persistent//lib/net/http/persistent.rb#152
class Net::HTTP::Persistent
  # Creates a new Net::HTTP::Persistent.
  #
  # Set a +name+ for fun.  Your library name should be good enough, but this
  # otherwise has no purpose.
  #
  # +proxy+ may be set to a URI::HTTP or :ENV to pick up proxy options from
  # the environment.  See proxy_from_env for details.
  #
  # In order to use a URI for the proxy you may need to do some extra work
  # beyond URI parsing if the proxy requires a password:
  #
  #   proxy = URI 'http://proxy.example'
  #   proxy.user     = 'AzureDiamond'
  #   proxy.password = 'hunter2'
  #
  # Set +pool_size+ to limit the maximum number of connections allowed.
  # Defaults to 1/4 the number of allowed file handles or 256 if your OS does
  # not support a limit on allowed file handles.  You can have no more than
  # this many threads with active HTTP transactions.
  #
  # @return [Persistent] a new instance of Persistent
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#501
  def initialize(name: T.unsafe(nil), proxy: T.unsafe(nil), pool_size: T.unsafe(nil)); end

  # An SSL certificate authority.  Setting this will set verify_mode to
  # VERIFY_PEER.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#257
  def ca_file; end

  # Sets the SSL certificate authority file.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#567
  def ca_file=(file); end

  # A directory of SSL certificates to be used as certificate authorities.
  # Setting this will set verify_mode to VERIFY_PEER.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#263
  def ca_path; end

  # Sets the SSL certificate authority path.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#576
  def ca_path=(path); end

  # This client's OpenSSL::X509::Certificate
  #
  # For Net::HTTP parity
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#246
  def cert; end

  # Sets this client's OpenSSL::X509::Certificate
  # For Net::HTTP parity
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#555
  def cert=(certificate); end

  # An SSL certificate store.  Setting this will override the default
  # certificate store.  See verify_mode for more information.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#269
  def cert_store; end

  # Overrides the default SSL certificate store used for verifying
  # connections.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#586
  def cert_store=(store); end

  # This client's OpenSSL::X509::Certificate
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#246
  def certificate; end

  # Sets this client's OpenSSL::X509::Certificate
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#555
  def certificate=(certificate); end

  # The ciphers allowed for SSL connections
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#274
  def ciphers; end

  # The ciphers allowed for SSL connections
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#595
  def ciphers=(ciphers); end

  # Creates a new connection for +uri+
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#619
  def connection_for(uri); end

  # Sends debug_output to this IO via Net::HTTP#set_debug_output.
  #
  # Never use this method in production code, it causes a serious security
  # hole.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#287
  def debug_output; end

  # Sends debug_output to this IO via Net::HTTP#set_debug_output.
  #
  # Never use this method in production code, it causes a serious security
  # hole.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#287
  def debug_output=(_arg0); end

  # CGI::escape wrapper
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#680
  def escape(str); end

  # Returns true if the connection should be reset due to an idle timeout, or
  # maximum request count, false otherwise.
  #
  # @return [Boolean]
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#696
  def expired?(connection); end

  # Extra certificates to be added to the certificate chain
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#279
  def extra_chain_cert; end

  # Extra certificates to be added to the certificate chain.
  # It is only supported starting from Net::HTTP version 0.1.1
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#605
  def extra_chain_cert=(extra_chain_cert); end

  # Finishes the Net::HTTP +connection+
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#725
  def finish(connection); end

  # Current connection generation
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#292
  def generation; end

  # Headers that are added to every request using Net::HTTP#add_field
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#297
  def headers; end

  # Returns the HTTP protocol version for +uri+
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#736
  def http_version(uri); end

  # Maps host:port to an HTTP version.  This allows us to enable version
  # specific features.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#303
  def http_versions; end

  # Maximum time an unused connection can remain idle before being
  # automatically closed.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#309
  def idle_timeout; end

  # Maximum time an unused connection can remain idle before being
  # automatically closed.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#309
  def idle_timeout=(_arg0); end

  # The value sent in the Keep-Alive header.  Defaults to 30.  Not needed for
  # HTTP/1.1 servers.
  #
  # This may not work correctly for HTTP/1.0 servers
  #
  # This method may be removed in a future version as RFC 2616 does not
  # require this header.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#333
  def keep_alive; end

  # The value sent in the Keep-Alive header.  Defaults to 30.  Not needed for
  # HTTP/1.1 servers.
  #
  # This may not work correctly for HTTP/1.0 servers
  #
  # This method may be removed in a future version as RFC 2616 does not
  # require this header.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#333
  def keep_alive=(_arg0); end

  # This client's SSL private key
  #
  # For Net::HTTP parity
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#353
  def key; end

  # Sets this client's SSL private key
  # For Net::HTTP parity
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#784
  def key=(key); end

  # Maximum number of requests on a connection before it is considered expired
  # and automatically closed.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#315
  def max_requests; end

  # Maximum number of requests on a connection before it is considered expired
  # and automatically closed.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#315
  def max_requests=(_arg0); end

  # Number of retries to perform if a request fails.
  #
  # See also #max_retries=, Net::HTTP#max_retries=.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#322
  def max_retries; end

  # Set the maximum number of retries for a request.
  #
  # Defaults to one retry.
  #
  # Set this to 0 to disable retries.
  #
  # @raise [ArgumentError]
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#754
  def max_retries=(retries); end

  # Maximum SSL version to use, e.g. :TLS1_2
  #
  # By default, the version will be negotiated automatically between client
  # and server.  Ruby 2.5 and newer only.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#437
  def max_version; end

  # maximum SSL version to use
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1110
  def max_version=(max_version); end

  # Minimum SSL version to use, e.g. :TLS1_1
  #
  # By default, the version will be negotiated automatically between client
  # and server.  Ruby 2.5 and newer only.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#429
  def min_version; end

  # Minimum SSL version to use
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1101
  def min_version=(min_version); end

  # The name for this collection of persistent connections.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#338
  def name; end

  # List of host suffixes which will not be proxied
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#368
  def no_proxy; end

  # Adds "http://" to the String +uri+ if it is missing.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#743
  def normalize_uri(uri); end

  # Seconds to wait until a connection is opened.  See Net::HTTP#open_timeout
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#343
  def open_timeout; end

  # Seconds to wait until a connection is opened.  See Net::HTTP#open_timeout
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#343
  def open_timeout=(_arg0); end

  # Headers that are added to every request using Net::HTTP#[]=
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#348
  def override_headers; end

  # Pipelines +requests+ to the HTTP server at +uri+ yielding responses if a
  # block is given.  Returns all responses received.
  #
  # See
  # Net::HTTP::Pipeline[https://rdoc.info/gems/net-http-pipeline/Net/HTTP/Pipeline]
  # for further details.
  #
  # Only if <tt>net-http-pipeline</tt> was required before
  # <tt>net-http-persistent</tt> #pipeline will be present.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#775
  def pipeline(uri, requests, &block); end

  # Test-only accessor for the connection pool
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#373
  def pool; end

  # This client's SSL private key
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#353
  def private_key; end

  # Sets this client's SSL private key
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#784
  def private_key=(key); end

  # Sets the proxy server.  The +proxy+ may be the URI of the proxy server,
  # the symbol +:ENV+ which will read the proxy from the environment or nil to
  # disable use of a proxy.  See #proxy_from_env for details on setting the
  # proxy from the environment.
  #
  # If the proxy URI is set after requests have been made, the next request
  # will shut-down and re-open all connections.
  #
  # The +no_proxy+ query parameter can be used to specify hosts which shouldn't
  # be reached via proxy; if set it should be a comma separated list of
  # hostname suffixes, optionally with +:port+ appended, for example
  # <tt>example.com,some.host:8080</tt>.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#807
  def proxy=(proxy); end

  # Returns true when proxy should by bypassed for host.
  #
  # @return [Boolean]
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#881
  def proxy_bypass?(host, port); end

  # Creates a URI for an HTTP proxy server from ENV variables.
  #
  # If +HTTP_PROXY+ is set a proxy will be returned.
  #
  # If +HTTP_PROXY_USER+ or +HTTP_PROXY_PASS+ are set the URI is given the
  # indicated user and password unless HTTP_PROXY contains either of these in
  # the URI.
  #
  # The +NO_PROXY+ ENV variable can be used to specify hosts which shouldn't
  # be reached via proxy; if set it should be a comma separated list of
  # hostname suffixes, optionally with +:port+ appended, for example
  # <tt>example.com,some.host:8080</tt>. When set to <tt>*</tt> no proxy will
  # be returned.
  #
  # For Windows users, lowercase ENV variables are preferred over uppercase ENV
  # variables.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#854
  def proxy_from_env; end

  # The URL through which requests will be proxied
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#363
  def proxy_uri; end

  # Seconds to wait until reading one block.  See Net::HTTP#read_timeout
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#378
  def read_timeout; end

  # Seconds to wait until reading one block.  See Net::HTTP#read_timeout
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#378
  def read_timeout=(_arg0); end

  # Forces reconnection of all HTTP connections, including TLS/SSL
  # connections.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#897
  def reconnect; end

  # Forces reconnection of only TLS/SSL connections.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#904
  def reconnect_ssl; end

  # Makes a request on +uri+.  If +req+ is nil a Net::HTTP::Get is performed
  # against +uri+.
  #
  # If a block is passed #request behaves like Net::HTTP#request (the body of
  # the response will not have been read).
  #
  # +req+ must be a Net::HTTPGenericRequest subclass (see Net::HTTP for a list).
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#936
  def request(uri, req = T.unsafe(nil), &block); end

  # Creates a GET request if +req_or_uri+ is a URI and adds headers to the
  # request.
  #
  # Returns the request.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#975
  def request_setup(req_or_uri); end

  # Finishes then restarts the Net::HTTP +connection+
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#911
  def reset(connection); end

  # By default SSL sessions are reused to avoid extra SSL handshakes.  Set
  # this to false if you have problems communicating with an HTTPS server
  # like:
  #
  #   SSL_connect [...] read finished A: unexpected message (OpenSSL::SSL::SSLError)
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#392
  def reuse_ssl_sessions; end

  # By default SSL sessions are reused to avoid extra SSL handshakes.  Set
  # this to false if you have problems communicating with an HTTPS server
  # like:
  #
  #   SSL_connect [...] read finished A: unexpected message (OpenSSL::SSL::SSLError)
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#392
  def reuse_ssl_sessions=(_arg0); end

  # Shuts down all connections
  #
  # *NOTE*: Calling shutdown for can be dangerous!
  #
  # If any thread is still using a connection it may cause an error!  Call
  # #shutdown when you are completely done making requests!
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1006
  def shutdown; end

  # An array of options for Socket#setsockopt.
  #
  # By default the TCP_NODELAY option is set on sockets.
  #
  # To set additional options append them to this array:
  #
  #   http.socket_options << [Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1]
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#403
  def socket_options; end

  # Enables SSL on +connection+
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1013
  def ssl(connection); end

  # Current SSL connection generation
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#408
  def ssl_generation; end

  # SSL session lifetime
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#413
  def ssl_timeout; end

  # SSL session lifetime
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1083
  def ssl_timeout=(ssl_timeout); end

  # SSL version to use.
  #
  # By default, the version will be negotiated automatically between client
  # and server.  Ruby 1.9 and newer only. Deprecated since Ruby 2.5.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#421
  def ssl_version; end

  # SSL version to use
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1092
  def ssl_version=(ssl_version); end

  # Starts the Net::HTTP +connection+
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#707
  def start(http); end

  # Where this instance's last-use times live in the thread local variables
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#442
  def timeout_key; end

  # CGI::unescape wrapper
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#687
  def unescape(str); end

  # SSL verification callback.  Used when ca_file or ca_path is set.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#447
  def verify_callback; end

  # SSL verification callback.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1150
  def verify_callback=(callback); end

  # Sets the depth of SSL certificate verification
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#452
  def verify_depth; end

  # Sets the depth of SSL certificate verification
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1119
  def verify_depth=(verify_depth); end

  # HTTPS verify_hostname.
  #
  # If a client sets this to true and enables SNI with SSLSocket#hostname=,
  # the hostname verification on the server certificate is performed
  # automatically during the handshake using
  # OpenSSL::SSL.verify_certificate_identity().
  #
  # You can set +verify_hostname+ as true to use hostname verification
  # during the handshake.
  #
  # NOTE: This works with Ruby > 3.0.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#478
  def verify_hostname; end

  # Sets the HTTPS verify_hostname.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1141
  def verify_hostname=(verify_hostname); end

  # HTTPS verify mode.  Defaults to OpenSSL::SSL::VERIFY_PEER which verifies
  # the server certificate.
  #
  # If no ca_file, ca_path or cert_store is set the default system certificate
  # store is used.
  #
  # You can use +verify_mode+ to override any default values.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#463
  def verify_mode; end

  # Sets the HTTPS verify mode.  Defaults to OpenSSL::SSL::VERIFY_PEER.
  #
  # Setting this to VERIFY_NONE is a VERY BAD IDEA and should NEVER be used.
  # Securely transfer the correct certificate and update the default
  # certificate store or set the ca file instead.
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#1132
  def verify_mode=(verify_mode); end

  # Seconds to wait until writing one block.  See Net::HTTP#write_timeout
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#383
  def write_timeout; end

  # Seconds to wait until writing one block.  See Net::HTTP#write_timeout
  #
  # source://net-http-persistent//lib/net/http/persistent.rb#383
  def write_timeout=(_arg0); end

  class << self
    # Use this method to detect the idle timeout of the host at +uri+.  The
    # value returned can be used to configure #idle_timeout.  +max+ controls the
    # maximum idle timeout to detect.
    #
    # After
    #
    # Idle timeout detection is performed by creating a connection then
    # performing a HEAD request in a loop until the connection terminates
    # waiting one additional second per loop.
    #
    # NOTE:  This may not work on ruby > 1.9.
    #
    # source://net-http-persistent//lib/net/http/persistent.rb#207
    def detect_idle_timeout(uri, max = T.unsafe(nil)); end
  end
end

# A Net::HTTP connection wrapper that holds extra information for managing the
# connection's lifetime.
#
# source://net-http-persistent//lib/net/http/persistent/connection.rb#5
class Net::HTTP::Persistent::Connection
  # @return [Connection] a new instance of Connection
  #
  # source://net-http-persistent//lib/net/http/persistent/connection.rb#15
  def initialize(http_class, http_args, ssl_generation); end

  # source://net-http-persistent//lib/net/http/persistent/connection.rb#22
  def close; end

  # source://net-http-persistent//lib/net/http/persistent/connection.rb#22
  def finish; end

  # source://net-http-persistent//lib/net/http/persistent/connection.rb#7
  def http; end

  # source://net-http-persistent//lib/net/http/persistent/connection.rb#7
  def http=(_arg0); end

  # Returns the value of attribute last_use.
  #
  # source://net-http-persistent//lib/net/http/persistent/connection.rb#9
  def last_use; end

  # Sets the attribute last_use
  #
  # @param value the value to set the attribute last_use to.
  #
  # source://net-http-persistent//lib/net/http/persistent/connection.rb#9
  def last_use=(_arg0); end

  # Returns the value of attribute requests.
  #
  # source://net-http-persistent//lib/net/http/persistent/connection.rb#11
  def requests; end

  # Sets the attribute requests
  #
  # @param value the value to set the attribute requests to.
  #
  # source://net-http-persistent//lib/net/http/persistent/connection.rb#11
  def requests=(_arg0); end

  # source://net-http-persistent//lib/net/http/persistent/connection.rb#30
  def reset; end

  # source://net-http-persistent//lib/net/http/persistent/connection.rb#35
  def ressl(ssl_generation); end

  # Returns the value of attribute ssl_generation.
  #
  # source://net-http-persistent//lib/net/http/persistent/connection.rb#13
  def ssl_generation; end

  # Sets the attribute ssl_generation
  #
  # @param value the value to set the attribute ssl_generation to.
  #
  # source://net-http-persistent//lib/net/http/persistent/connection.rb#13
  def ssl_generation=(_arg0); end
end

# source://net-http-persistent//lib/net/http/persistent.rb#174
Net::HTTP::Persistent::DEFAULT_POOL_SIZE = T.let(T.unsafe(nil), Integer)

# The beginning of Time
#
# source://net-http-persistent//lib/net/http/persistent.rb#157
Net::HTTP::Persistent::EPOCH = T.let(T.unsafe(nil), Time)

# Error class for errors raised by Net::HTTP::Persistent.  Various
# SystemCallErrors are re-raised with a human-readable message under this
# class.
#
# source://net-http-persistent//lib/net/http/persistent.rb#192
class Net::HTTP::Persistent::Error < ::StandardError; end

# Is OpenSSL available?  This test works with autoload
#
# source://net-http-persistent//lib/net/http/persistent.rb#162
Net::HTTP::Persistent::HAVE_OPENSSL = T.let(T.unsafe(nil), String)

# source://net-http-persistent//lib/net/http/persistent/pool.rb#1
class Net::HTTP::Persistent::Pool < ::ConnectionPool
  # @return [Pool] a new instance of Pool
  #
  # source://net-http-persistent//lib/net/http/persistent/pool.rb#6
  def initialize(options = T.unsafe(nil), &block); end

  # source://net-http-persistent//lib/net/http/persistent/pool.rb#3
  def available; end

  # source://net-http-persistent//lib/net/http/persistent/pool.rb#13
  def checkin(net_http_args); end

  # source://net-http-persistent//lib/net/http/persistent/pool.rb#43
  def checkout(net_http_args); end

  # source://net-http-persistent//lib/net/http/persistent/pool.rb#4
  def key; end

  # source://net-http-persistent//lib/net/http/persistent/pool.rb#58
  def shutdown; end
end

# source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#1
class Net::HTTP::Persistent::TimedStackMulti < ::ConnectionPool::TimedStack
  # @return [TimedStackMulti] a new instance of TimedStackMulti
  #
  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#13
  def initialize(size = T.unsafe(nil), &block); end

  # @return [Boolean]
  #
  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#22
  def empty?; end

  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#26
  def length; end

  private

  # @return [Boolean]
  #
  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#32
  def connection_stored?(options = T.unsafe(nil)); end

  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#36
  def fetch_connection(options = T.unsafe(nil)); end

  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#44
  def lru_update(connection_args); end

  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#49
  def shutdown_connections; end

  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#55
  def store_connection(obj, options = T.unsafe(nil)); end

  # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#60
  def try_create(options = T.unsafe(nil)); end

  class << self
    # Returns a new hash that has arrays for keys
    #
    # Using a class method to limit the bindings referenced by the hash's
    # default_proc
    #
    # source://net-http-persistent//lib/net/http/persistent/timed_stack_multi.rb#9
    def hash_of_arrays; end
  end
end

# The version of Net::HTTP::Persistent you are using
#
# source://net-http-persistent//lib/net/http/persistent.rb#185
Net::HTTP::Persistent::VERSION = T.let(T.unsafe(nil), String)
