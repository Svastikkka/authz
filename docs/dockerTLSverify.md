1. Create overeide directory PATH: /etc/systemd/system/docker.service.d/override.conf for Rocky Linux
2. Create a certificates (both server certificate and client certificates) and put in ~/.docker folder for root user
3. Add override command
```bash
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd://  --authorization-plugin=authz-broker  --containerd=/run/containerd/containerd.sock -H tcp://0.0.0.0:2376 --tlsverify --tlscacert=/root/.docker/ca.pem --tlscert=/root/.docker/server-cert.pem --tlskey=/root/.docker/server-key.pem
```
4. Start a authz container
```bash
docker run -d  --restart=always -v /root/Desktop/policy.json:/var/lib/authz-broker/policy.json -v /run/docker/plugins/:/run/docker/plugins twistlock/authz-broker
```
Note:

- `/root/Desktop/policy.json` ==> Baremetal path of policy.json
- `/run/docker/plugins/`  ==> Baremetal path of plugins