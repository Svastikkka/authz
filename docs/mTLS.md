To enable mutual TLS (mTLS) in Docker with SAN (Subject Alternative Name), you have provided a detailed set of steps for setting up certificate authority (CA), server, and client certificates. Here’s a summary along with additional steps to ensure SAN support in the certificates and Docker configuration:

### 1. Modify OpenSSL Configuration for SAN
When creating the CA, server, and client certificates, you need to ensure that SAN is properly configured. In the OpenSSL configuration file (`openssl.cnf`), locate the `[ v3_req ]` and `[ v3_ca ]` sections and modify them to support SAN:

```ini
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca # Required to support v3 extensions

[ v3_req ]
subjectAltName = @alt_names

[ v3_ca ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = server.yourdomain.com
IP.1 = 127.0.0.1
```

This adds a SAN entry for both DNS and IP. You can replace `server.yourdomain.com` and `127.0.0.1` with your actual server hostname and IP address.

### 2. Steps for Creating CA Certificate
Follow your provided steps to create the CA certificate, starting with:

1. Create the directory structure and necessary files:
   ```bash
   mkdir -p /root/mtls/{certs,private}
   cd /root/mtls/
   echo 01 > serial
   touch index.txt
   ```

2. Copy and modify `openssl.cnf` to include SAN entries (as shown above).

3. Generate the CA's private key:
   ```bash
   openssl genrsa -out private/cakey.pem 4096
   ```

4. Create the CA certificate:
   ```bash
   openssl req -new -x509 -days 3650 -config /root/mtls/openssl.cnf -key private/cakey.pem -out certs/cacert.pem
   ```

### 3. Create Client and Server Certificates with SAN

For both the client and server certificates, ensure that the SAN entries are included in the CSRs (Certificate Signing Requests). You can modify the `openssl.cnf` file to use SAN as mentioned above.

- **Create Client Key and CSR:**
   ```bash
   openssl genrsa -out client.key.pem 4096
   openssl req -new -key client.key.pem -out client.csr -config /root/mtls/openssl.cnf
   ```

- **Create Server Key and CSR:**
   ```bash
   openssl genrsa -out server.key.pem 4096
   openssl req -new -key server.key.pem -out server.csr -config /root/mtls/openssl.cnf
   ```

After generating the CSRs, sign them with your CA:

- **Sign Client Certificate:**
   ```bash
   openssl ca -config /root/mtls/openssl.cnf -days 1650 -notext -batch -in client.csr -out client.cert.pem
   ```

- **Sign Server Certificate:**
   ```bash
   openssl ca -config /root/mtls/openssl.cnf -days 1650 -notext -batch -in server.csr -out server.cert.pem
   ```

### 4. Configure Docker for mTLS
To enable Docker to use these certificates, follow these steps:

1. **Copy Certificates:**
   - Place the server certificate (`server.cert.pem`), private key (`server.key.pem`), and CA certificate (`cacert.pem`) on the Docker host machine.

2. **Docker Daemon Configuration:**
   Edit Docker's configuration file (`/etc/docker/daemon.json`) to use the certificates for TLS verification:

   ```json
   {
     "tls": true,
     "tlsverify": true,
     "tlscacert": "/root/mtls/certs/cacert.pem",
     "tlscert": "/root/server_certs/server.cert.pem",
     "tlskey": "/root/server_certs/server.key.pem",
     "hosts": ["tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"]
   }
   ```

3. **Restart Docker:**
   After modifying the Docker configuration, restart the Docker service:
   ```bash
   systemctl restart docker
   ```

### 5. Verify mTLS Communication

After configuring Docker for mTLS, verify the setup:

- **Server-side TLS validation:**
   On the server, run:
   ```bash
   openssl s_server -accept 3000 -CAfile /root/mtls/certs/cacert.pem -cert /root/server_certs/server.cert.pem -key /root/server_certs/server.key.pem -state
   ```

- **Client-side TLS connection:**
   On the client, use:
   ```bash
   openssl s_client -connect 127.0.0.1:3000 -key /root/client_certs/client.key.pem -cert /root/client_certs/client.cert.pem -CAfile /root/mtls/certs/cacert.pem -state
   ```

This will allow mutual authentication between the client and server using mTLS with SAN verification.