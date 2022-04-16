# tls-nodejs
A TLS-based client-server connection self-signing the certificates using OpenSSL. 

## Running
Install [OpenSSL](https://www.openssl.org), then:
```sh
$ setup.sh
$ node tlsServer.js
$ node tlsClient.js # in another terminal window
```
You should be able to see the execution logs at the terminal windows.
