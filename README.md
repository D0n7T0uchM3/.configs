VIM
```bash
curl -fLsS https://raw.githubusercontent.com/D0n7T0uchM3/.configs/refs/heads/main/.vimrc -o ~/.vimrc
```

BASH
```bash
curl -fLsS https://raw.githubusercontent.com/D0n7T0uchM3/.configs/refs/heads/main/.bashrc -o ~/.bashrc
```

NODE EXPORTER (Prometheus)
```bash
curl -fLsS https://raw.githubusercontent.com/D0n7T0uchM3/.configs/refs/heads/main/start-node-exporter.sh | sudo bash -s -- --service
```

IPTABLES
```bash
curl -fLsS https://raw.githubusercontent.com/D0n7T0uchM3/.configs/refs/heads/main/setup-iptables.sh | sudo bash -s -- --ports 22/tcp,80/tcp,443/tcp,3000/tcp
```
