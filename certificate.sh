set -eu

cd /home/shashi
echo "you are now in $PWD"

if [ ! -d ".docker/" ]
then
    echo "Directory ./docker/ does not exist"
    echo "Creating the directory"
    mkdir .docker
fi

cd .docker/
echo "Type in your certificate password (characters are not echoed)"
read -p '>' -s PASSWORD

echo "Type in the server name you’ll use to connect to the Docker server"
read -p '>' SERVER

# Generate CA key
openssl genrsa -aes256 -passout pass:$PASSWORD -out ca-key.pem 2048

# Self-sign CA certificate
openssl req -new -x509 -days 365 -key ca-key.pem -passin pass:$PASSWORD -sha256 -out ca.pem -subj "/C=TR/ST=./L=./O=./CN=$SERVER"

# Generate server key
openssl genrsa -out server-key.pem 2048

# Create a server certificate request
openssl req -new -key server-key.pem -subj "/CN=$SERVER" -out server.csr

# Create SAN config file with "shashi" as DNS and IP 192.168.0.206
echo "subjectAltName = DNS:shashi,IP:192.168.0.206" > san.cnf

# Sign the server certificate with SAN
openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -passin "pass:$PASSWORD" -CAcreateserial -out server-cert.pem -extfile san.cnf

# Generate client key
openssl genrsa -out key.pem 2048

# Create client certificate request. Note: CN need to be change for each user
openssl req -subj '/CN=shashi' -new -key key.pem -out client.csr

# Create extension config for client certificate
sh -c 'echo "extendedKeyUsage = clientAuth" > extfile.cnf'

# Sign client certificate
openssl x509 -req -days 365 -in client.csr -CA ca.pem -CAkey ca-key.pem -passin "pass:$PASSWORD" -CAcreateserial -out cert.pem -extfile extfile.cnf

# Clean up unnecessary files
rm ca.srl client.csr extfile.cnf server.csr san.cnf

# Set appropriate permissions
chmod 0400 ca-key.pem key.pem server-key.pem
chmod 0444 ca.pem server-cert.pem cert.pem
