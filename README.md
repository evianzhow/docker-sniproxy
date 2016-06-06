# sniproxy

A proxy server that redirects based on the `Host` header (HTTP) or Server Name
Identification header (HTTPS) present in the request.

## Deployment

Most aspects of `sniproxy` are configured in environment variables.  This is in
contrast to many `sniproxy` containers seen which either hardcode configurations
or expect to be provided with a hand-crafted configuration file.

### Global settings

The following are global settings for `sniproxy`, these should not need
modification but are listed for documentation purposes:

* `SNIPROXY_USER` (default: `nobody`): The user `sniproxy` runs as after binding
  ports.
* `SNIPROXY_PIDFILE`: The PID file to write the `sniproxy` PID to.

### DNS configuration

By default, `sniproxy` will use the configuration in `/etc/resolv.conf`, but
also incorporates its own resolver and can make decisions based on that.

DNS servers are specified using parameters `SNIPROXY_NS_SRVn` where `n`
increments starting at 0.  These specify individual nameservers to try.

DNS domain search order is specified using parameters `SNIPROXY_NS_SEARCHn`,
again with `n` incrementing from 0.

Finally, you can specify `SNIPROXY_NS_MODE` to dictate the resolution mode:
* `ipv4_only`: Only resolve IPv4 addresses
* `ipv6_only`: Only resolve IPv6 addresses
* `ipv4_first`: Resolve both IPv4 and IPv6 but try IPv4 first
* `ipv6_first`: Resolve both IPv4 and IPv6 but try IPv6 first

### Listening socket configuration

The port numbers used by `sniproxy`, protocol types and redirection tables are
defined using the following parameters.  In all of these, the `n` is an integer
that increments from 0 for each socket being configured.

* `SNIPROXY_LISTENn_PROTO`: (Required)
  Protocol in use, either `http` or `tls` (HTTPS).
* `SNIPROXY_LISTENn_PORT`: (Required) TCP port number to use.
* `SNIPROXY_LISTENn_ADDR`: (Optional) Bind address for socket.  Default is to
  bind to all possible addresses.  (aka `0.0.0.0` on IPv4 or `::` on IPv6)
* `SNIPROXY_LISTENn_FALLBACK`: (Optional) Address and port number of a server
  to direct clients to in the event that `sniproxy` can't figure out what server
  is requested.
* `SNIPROXY_LISTENn_SOURCE`: (Optional) Source IP to use for requests to the
  back-end server.
* `SNIPROXY_LISTENn_TABLE`: (Optional) Redirection table to use for this socket.
  By default, the default table is used.  This should be the name of a table
  given in the proxy table configuration.

### Proxy table configuration

The actual source/destination mapping tables are defined here.  Table `0` is
hard-coded as being the "default" table, all tables following `0` must be named
explicitly using the parameter `SNIPROXY_TABLEn` (where `n` is `1` onwards).

The source hostname pattern and destination address/port is specified using
parameter pairs `SNIPROXY_TABLEn_SRCm` (source pattern) and
`SNIPROXY_TABLEn_DESTm` (destination address).

## Known issues

`SNIPROXY_USER` presently has no effect as `supervisord` requires we run
`sniproxy` in the foreground and `sniproxy` does not allow us to drop privileges
*and* remain in the foreground.  This issue has been raised
[upstream](https://github.com/dlundquist/sniproxy/issues/203).

## History

See [CHANGELOG.md](CHANGELOG.md)

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://bitbucket.org/vrtsystems/docker-sniproxy#tags). 

## References

* [sniproxy](https://github.com/dlundquist/sniproxy)
* [VRT Systems](http://vrt.com.au)
