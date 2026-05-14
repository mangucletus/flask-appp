# flask-app

Tiny Flask demo for AWS deployment exercises (EC2, ALB + ASG, CodeDeploy).

## Endpoints
- `GET /` — landing page with host + version
- `POST /echo` — echoes JSON body back with the app version
- `GET /health` — readiness probe used by the ALB target group

## Local dev
```bash
python3 -m venv venv
./venv/bin/pip install -r requirement.txt
./venv/bin/python app.py
# open http://localhost:8000
```

## Deploying to AWS
See [`RUNBOOK.md`](RUNBOOK.md) for the full single-EC2 and ALB + ASG walkthroughs,
SG configuration, and common-issue troubleshooting.
