#!/usr/bin/env node
'use strict';

const CLIENT_PORT = 8000;
const CLIENT_HOST = 'localhost';
const CLIENT_KEY_PATH = 'certificates/clientCertificate/clientCertificate.key';
const CLIENT_CERTIFICATE_PATH = 'certificates/clientCertificate/clientCertificate.crt';
const AUTORITY_CERTIFICATE_PATH = 'certificates/caCertificate/caCertificate.crt';
const DEFAULT_ENCODING = 'utf8';

const tlsModule = require('tls');
const fileSystem = require('fs');

const secureConnectionListener = () => {
    console.log(
        'Client conectado',
        tlsSocket.authorized
            ? 'autorizado'
            : 'não autorizado'
    );
    if (!tlsSocket.authorized) {
        console.error("Erro: Socket TLS não autorizado: ", tlsSocket.authorizationError());
        tlsSocket.end();
    }
};

const tlsOptions = {
    port: CLIENT_PORT,
    host: CLIENT_HOST,
    key: fileSystem.readFileSync(CLIENT_KEY_PATH),
    ca: fileSystem.readFileSync(AUTORITY_CERTIFICATE_PATH),
    cert: fileSystem.readFileSync(CLIENT_CERTIFICATE_PATH)
};

const tlsSocket = tlsModule.connect(tlsOptions, secureConnectionListener)
    .setEncoding(DEFAULT_ENCODING)
    .on('data', (data) => {
        console.log("Dados recebidos: ", data);
        tlsSocket.end();
    })
    .on('close', () => {
        console.log("Conexão fechada");
    })
    .on('end', () => {
        console.log("Conexão encerrada");
    })
    .on('error', (error) => {
        console.error("Um erro inesperado ocorreu", error);
        tlsSocket.destroy();
    });
