#!/usr/bin/env node
'use strict';

const fileSystem = require('fs');
const tlsModule = require('tls');
const SERVER_PORT = 8000;
const SERVER_KEY_PATH = 'certificates/serverCertificate/serverCertificate.key';
const SERVER_CERTIFICATE_PATH = 'certificates/serverCertificate/serverCertificate.crt';
const AUTORITY_CERTIFICATE_PATH = 'certificates/caCertificate/caCertificate.crt';
const DEFAULT_ENCODING = 'utf8';

const secureConnectionListener = (tlsSocket) => {
    tlsSocket.write('Uncle Bob We Love You\n');
    tlsSocket.setEncoding(DEFAULT_ENCODING);
    tlsSocket.pipe(tlsSocket);
}

const tlsOptions = {
    requestCert: true,
    key: fileSystem.readFileSync(SERVER_KEY_PATH),
    ca: fileSystem.readFileSync(AUTORITY_CERTIFICATE_PATH),
    cert: fileSystem.readFileSync(SERVER_CERTIFICATE_PATH),
};

const tlsServer = tlsModule.createServer(
    tlsOptions,
    secureConnectionListener,
).on('connection', () => { console.log('Conexão insegura estabelecida'); })
    .on('secureConnection', (tlsSocket) => {
        console.log('Conexão segura estabelecida')
        console.log('Client autorizado: ', tlsSocket.authorized);
    })
    .listen(SERVER_PORT, () => {
        console.log('Servidor TLS escutando na porta ' + SERVER_PORT + '\n');
    });
