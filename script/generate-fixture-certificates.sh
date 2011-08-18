#!/bin/sh

rm -rf spec/fixtures/certificates_tmp
mkdir spec/fixtures/certificates_tmp
cd spec/fixtures/certificates_tmp

# root CA
mkdir certs crl newcerts private
echo "01" > serial
touch index.txt
openssl genrsa -out private/cakey.pem 4096
openssl req -new -x509 -nodes -sha1 -days 10000 -key private/cakey.pem -out cacert.pem -config ../openssl.cnf

# intermediate CA
mkdir intermediate-ca
cd intermediate-ca
mkdir certs crl newcerts private
echo "01" > serial
touch index.txt
openssl genrsa -out private/cakey.pem 4096
openssl req -new -nodes -sha1 -key private/cakey.pem -out intermediate-ca.csr -config ../../openssl.cnf
mv intermediate-ca.csr ..
cd ..
openssl ca -extensions v3_ca -days 10000 -out intermediate-ca.pem -in intermediate-ca.csr -config ../openssl.cnf
mv intermediate-ca.pem intermediate-ca/cacert.pem

# server certificate
mkdir server-cert
cd server-cert
mkdir certs crl newcerts private
echo "01" > serial
touch index.txt
openssl genrsa -out private/cakey.pem 4096
openssl req -new -nodes -sha1 -key private/cakey.pem -out server-cert.csr -config ../../openssl.cnf
mv server-cert.csr ../intermediate-ca
cd ../intermediate-ca
openssl ca -extensions v3_ca -days 10000 -out server-cert.pem -in server-cert.csr -config ../../openssl.cnf
mv server-cert.pem ../server-cert/cacert.pem
cd ..

# other intermediate CA
mkdir other-intermediate-ca
cd other-intermediate-ca
mkdir certs crl newcerts private
echo "01" > serial
touch index.txt
openssl genrsa -out private/cakey.pem 4096
openssl req -new -nodes -sha1 -key private/cakey.pem -out other-intermediate-ca.csr -config ../../openssl.cnf
mv other-intermediate-ca.csr ..
cd ..
openssl ca -extensions v3_ca -days 10000 -out other-intermediate-ca.pem -in other-intermediate-ca.csr -config ../openssl.cnf
mv other-intermediate-ca.pem other-intermediate-ca/cacert.pem

cd ..
rm -rf certificates
mkdir certificates
mv certificates_tmp/cacert.pem certificates/root_ca.pem
mv certificates_tmp/intermediate-ca/cacert.pem certificates/intermediate_ca.pem
mv certificates_tmp/server-cert/cacert.pem certificates/server.pem
mv certificates_tmp/other-intermediate-ca/cacert.pem certificates/other_intermediate_ca.pem
