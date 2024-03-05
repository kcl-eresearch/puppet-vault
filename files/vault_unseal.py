#!/usr/bin/python3

import hvac
import sys
import yaml

def get_secret(type, path, host=None, port=None, mount_point=None, mount_version=None, secret=None, username=None, password=None, client_crt=None, client_key=None):
    if type == "vault":
        client = hvac.Client(
            url="https://%s:%d" % (host, port),
            verify="/etc/ssl/certs/ca-certificates.crt"
        )
        if client_crt and client_key:
            client.auth.cert.login(
                cert_pem=client_crt,
                key_pem=client_key
            )
        if username and password:
            client.auth.userpass.login(
                username=username,
                password=password
            )
        if not client.is_authenticated():
            return False

        if mount_version == 2:
            result = client.secrets.kv.v2.read_secret_version(path=path, mount_point=mount_point)
            return result["data"]["data"][secret]
        else:
            result = client.secrets.kv.v1.read_secret(path=path, mount_point=mount_point)
            return result["data"][secret]

    else:
        try:
            with open(path) as fh:
                return fh.read().strip()
        except:
            return False

config_file = "/etc/vault_unseal/%s.yaml" % sys.argv[1]

try:
    with open(config_file) as fh:
        config = yaml.safe_load(fh)
except Exception as e:
    sys.exit("Cannot load config file %s: %s" % (config_file, e))

client = hvac.Client(url="https://%s:%d" % (config["vault_host"], config["vault_port"]))

if not client.sys.is_sealed():
    sys.exit(0)

for portion in config["unseal_portions"]:
    secret = get_secret(**portion)
    if secret:
        client.sys.submit_unseal_key(secret)
