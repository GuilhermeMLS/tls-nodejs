#!/bin/bash

if test $# -eq 0; then
    echo "Como usar: ./setup.sh <caminho para gerar os certificados>"
    exit 0
elif test $# -ne 1; then
    echo "Argumentos inválidos"
    exit 1
fi

ROOT_PATH="$1"

mkdir -p "$ROOT_PATH"/certificates/{serverCertificate,clientCertificate,caCertificate,temp}
CERTIFICATE_PATH=$ROOT_PATH/certificates/caCertificate
SERVER_CERTIFICATES_PATH=$ROOT_PATH/certificates/serverCertificate
CLIENT_CERTIFICATE_PATH=$ROOT_PATH/certificates/clientCertificate
TEMP_PATH=$ROOT_PATH/certificates/temp
RSA_BITS=4096

echo -e "++++ TLS Client-Server: Setup do projeto ++++"
echo -e "Tópicos avançados em redes - UFPR"
echo -e "Guilherme M. Lopes dos Santos, GRR20163043"
echo -e "Cristopher Carcereri, GRR20163073\n"

echo -e "++++ Configuração dos certificados ++++\n"

echo -n "Largura de bits RSA (valor padrão: $RSA_BITS):"
read -r RSA_BITS

if [ ${#RSA_BITS} -eq 0 ]; then
    RSA_BITS=4096
fi

EXPIRATION_DEADLINE_IN_DAYS=365

echo -n "Dias até a expiração (valor padrão: $EXPIRATION_DEADLINE_IN_DAYS):"
read -r EXPIRATION_DEADLINE_IN_DAYS

if [ ${#EXPIRATION_DEADLINE_IN_DAYS} -eq 0 ]; then
    EXPIRATION_DEADLINE_IN_DAYS=365
fi

while [ ${#PASSWORD} -lt 5 ]; do
    echo -n "Senha dos certificados:"
    read -r -s PASSWORD
    echo
    if [ ${#PASSWORD} -lt 5 ]; then
        echo "A senha deve ter no mínimo cinco caracteres"
    fi
done

echo -e "++++ Configuração do OpenSSL ++++\n"

COUNTRY_CODE="BR"
echo -n "Código do país (duas letras) (valor padrão: $COUNTRY_CODE):"
read -r COUNTRY_CODE

if [ ${#COUNTRY_CODE} -eq 0 ]; then
    COUNTRY_CODE="BR"
fi

echo -n "Nome do estado:"
read -r STATE_NAME

if [ ${#STATE_NAME} -eq 0 ]; then
    STATE_NAME="."
fi

echo -n "Nome da cidade:"
read -r CITY_NAME

if [ ${#CITY_NAME} -eq 0 ]; then
    CITY_NAME="."
fi

ORGANIZATION_NAME="Alonso Monstro LTDA"
echo -n "Nome da organização (valor padrão: $ORGANIZATION_NAME):"
read -r ORGANIZATION_NAME

if [ ${#ORGANIZATION_NAME} -eq 0 ]; then
    ORGANIZATION_NAME="Alonso Monstro LTDA"
fi

echo -n "Nome do departamento:"
read -r DEPARTMENT

if [ ${#DEPARTMENT} -eq 0 ]; then
    DEPARTMENT="."
fi

SERVER_HOST="localhost"
echo -n "Host do servidor (valor padrão: $SERVER_HOST):"
read -r SERVER_HOST

if [ ${#SERVER_HOST} -eq 0 ]; then
    SERVER_HOST="localhost"
fi

echo -n "E-mail:"
read -r EMAIL_ADDRESS

if [ ${#EMAIL_ADDRESS} -gt 0 ]; then
    EMAIL_ADDRESS="/emailAddress=$EMAIL_ADDRESS"
fi

echo -e "\n"
echo "Atributos opcionais (seriam enviados junto com a requisição de certificado)"
echo -n "Nome da empresa (opcional):"
read -r OPTIONAL_ENTERPRISE_NAME

if [ ${#OPTIONAL_ENTERPRISE_NAME} -gt 0 ]; then
    OPTIONAL_ENTERPRISE_NAME="/unstructuredName=$OPTIONAL_ENTERPRISE_NAME"
fi

echo -e "\n"

OTHER_FIELDS=""
ADD_OTHER_FIELD="Y"

while [ "$ADD_OTHER_FIELD" = "y" ] || [ "$ADD_OTHER_FIELD" = "Y" ]; do
    ADD_OTHER_FIELD="N"
    echo -n "Add other field [y/N] ? "
    read -r ADD_OTHER_FIELD
    if [ "$ADD_OTHER_FIELD" = "y" ] || [ "$ADD_OTHER_FIELD" = "Y" ]; then
        echo -n "Field name: "
        read -r OTHER_FIELD_NAME
        echo -n "Field value: "
        read -r OTHER_FIELD_VALUE
        if [ ${#OTHER_FIELD_VALUE} -eq 0 ]; then
            OTHER_FIELD_VALUE="."
        fi
        OTHER_FIELDS="$OTHER_FIELDS/$OTHER_FIELD_NAME=$OTHER_FIELD_VALUE"
    fi
done

echo -e "++++ Gerando certificados... ++++\n"

echo -e "++ Gerando key da Autoridade de Certificação\n"
openssl genrsa -des3 -passout pass:"$PASSWORD" -out "$CERTIFICATE_PATH"/caCertificate.key $RSA_BITS
# Cria o certificado de autoridade
openssl req -new -x509 -days $EXPIRATION_DEADLINE_IN_DAYS -key "$CERTIFICATE_PATH"/caCertificate.key -out "$CERTIFICATE_PATH"/caCertificate.crt -passin pass:"$PASSWORD" -subj "/C=$COUNTRY_CODE/ST=$STATE_NAME/L=$CITY_NAME/O=$ORGANIZATION_NAME/OU=$DEPARTMENT/CN=.$OPTIONAL_ENTERPRISE_NAME$EMAIL_ADDRESS$GK_subjectAltName$OTHER_FIELDS"

echo -e "\n++ Gerando key do Servidor\n"
openssl genrsa -out "$SERVER_CERTIFICATES_PATH"/serverCertificate.key $RSA_BITS
openssl req -new -key "$SERVER_CERTIFICATES_PATH"/serverCertificate.key -out "$TEMP_PATH"/serverCertificate.csr -passout pass:"$PASSWORD" -subj "/C=$COUNTRY_CODE/ST=$STATE_NAME/L=$CITY_NAME/O=$ORGANIZATION_NAME/OU=$DEPARTMENT/CN=$SERVER_HOST$OPTIONAL_ENTERPRISE_NAME$EMAIL_ADDRESS$GK_subjectAltName$OTHER_FIELDS"
# ASSINANDO O CERTIFICADO DO SERVIDOR COM O CERTIFICADO AUTO-ASSINADO QUE FOI GERADO
openssl x509 -req -days $EXPIRATION_DEADLINE_IN_DAYS -passin pass:"$PASSWORD" -in "$TEMP_PATH"/serverCertificate.csr -CA "$CERTIFICATE_PATH"/caCertificate.crt -CAkey "$CERTIFICATE_PATH"/caCertificate.key -set_serial 01 -out "$SERVER_CERTIFICATES_PATH"/serverCertificate.crt

echo -e "\n++ Gerando key do Cliente\n"
openssl genrsa -out "$CLIENT_CERTIFICATE_PATH"/clientCertificate.key $RSA_BITS
openssl req -new -key "$CLIENT_CERTIFICATE_PATH"/clientCertificate.key -out "$TEMP_PATH"/clientCertificate.csr -passout pass:"$PASSWORD" -subj "/C=$COUNTRY_CODE/ST=$STATE_NAME/L=$CITY_NAME/O=$ORGANIZATION_NAME/OU=$DEPARTMENT/CN=CLIENT$OPTIONAL_ENTERPRISE_NAME$EMAIL_ADDRESS$GK_subjectAltName$OTHER_FIELDS"
openssl x509 -req -days 365 -passin pass:"$PASSWORD" -in "$TEMP_PATH"/clientCertificate.csr -CA "$CERTIFICATE_PATH"/caCertificate.crt -CAkey "$CERTIFICATE_PATH"/caCertificate.key -set_serial 01 -out "$CLIENT_CERTIFICATE_PATH"/clientCertificate.crt

rm -rf "$TEMP_PATH"

echo -e "++++ Certificados de cliente e servidor gerados! ++++\n"

exit 0
