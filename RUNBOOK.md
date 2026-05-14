# Runbook — Flask on AWS Demo

Quick reference for deploying this Flask app on EC2, either standalone or behind an ALB + Auto Scaling Group.

## App overview

- Flask + gunicorn, listening on **port 8000**
- Endpoints: `GET /`, `POST /echo`, `GET /health`
- Managed by `systemd` unit `flaskapp.service`
- Bootstrapped by `templates/user-data.sh` on first boot

---

## Demo 1 — Single EC2 instance

### Launch
1. Launch Ubuntu EC2 instance (t2.micro is fine).
2. Paste the contents of `templates/user-data.sh` into the **User data** field.
3. Attach a key pair and a security group (see below).

### Security Group
| Type | Port | Source |
|---|---|---|
| SSH | 22 | My IP |
| Custom TCP | 8000 | 0.0.0.0/0 |

### Verify
```bash
ssh -i ~/Downloads/flask-demo-key.pem ubuntu@<EC2-PUBLIC-IP>
sudo systemctl status flaskapp
curl -i http://localhost:8000
```
Then in the browser: `http://<EC2-PUBLIC-IP>:8000`

---

## Demo 2 — ALB + Auto Scaling Group

### Architecture
```
Internet → ALB :80 → Target Group :8000 → ASG instances (gunicorn :8000)
```

### Steps
1. **Launch Template** — uses `templates/user-data.sh`, same SG as below.
2. **Target Group**
   - Target type: **Instances**
   - Protocol: **HTTP**, Port: **8000** *(must match gunicorn — not 80)*
   - Health checks → Path: `/health`, Port: `traffic-port`, Success codes: `200`
3. **Application Load Balancer**
   - Internet-facing, HTTP:80 listener → forward to the target group above
4. **Auto Scaling Group**
   - Uses the launch template
   - Attached to the target group from step 2

### Security Groups
**ALB SG**
| Type | Port | Source |
|---|---|---|
| HTTP | 80 | 0.0.0.0/0 |
| Custom TCP | 8000 | 0.0.0.0/0 |

**EC2 / ASG instances SG**
| Type | Port | Source |
|---|---|---|
| SSH | 22 | My IP |
| Custom TCP | 8000 | ALB SG (or 0.0.0.0/0 for quick demo) |

### Verify
```bash
curl -i http://<alb-dns-name>/
```
Expect `HTTP/1.1 200 OK` from `Server: gunicorn`.

---

## Common issues

| Symptom | Cause | Fix |
|---|---|---|
| Browser can't reach EC2 directly | SG missing port 8000 inbound | Add Custom TCP 8000 from 0.0.0.0/0 |
| `Permission denied` binding port 80 | gunicorn runs as `ubuntu`, can't bind <1024 | Use port 8000 (current setup) or run as root |
| ALB **503 Service Unavailable** | No healthy targets | Check Target Group → Targets tab for failure reason |
| ALB **502 Bad Gateway** | TG port mismatch (set to 80, app on 8000) | Recreate TG on port **8000**; update listener + ASG |
| `git clone` fails in user-data | `<your-username>` placeholder not replaced | Edit `templates/user-data.sh` with real repo URL |
| Pip install fails with "No such file" | Filename mismatch between script and repo | Standard is `requirements.txt` (plural) — make sure both match |

---

## Debugging on a running instance

```bash
ssh -i ~/Downloads/flask-demo-key.pem ubuntu@<EC2-PUBLIC-IP>

# Cloud-init / user-data output
sudo cat /var/log/user-data.log
sudo cat /var/log/cloud-init-output.log

# Service status + recent logs
sudo systemctl status flaskapp --no-pager
sudo journalctl -u flaskapp -n 50 --no-pager

# What's listening
sudo ss -tlnp | grep 8000

# Hit the app locally to bypass the network
curl -i http://localhost:8000
curl -i http://localhost:8000/health
```

## Restarting the service after code changes
```bash
cd /home/ubuntu/flask-app
sudo -u ubuntu git pull
sudo systemctl restart flaskapp
```
