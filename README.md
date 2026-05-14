# flask-app

Tiny Flask demo for AWS deployment exercises (EC2, ALB + ASG, CodeDeploy).

## Endpoints
- `GET /` — landing page with host + version
- `POST /echo` — echoes JSON body back with the app version
- `GET /health` — readiness probe used by the ALB target group

## Local dev
```bash
cp .env.example .env          # fill in your values
python3 -m venv venv
./venv/bin/pip install -r requirement.txt
./venv/bin/python app.py
# open http://localhost:8000
```

## Deploying to AWS
See [`RUNBOOK.md`](RUNBOOK.md) for the full single-EC2 and ALB + ASG walkthroughs,
SG configuration, and common-issue troubleshooting.

## CI/CD setup (GitHub Actions → CodeDeploy)

The workflow at `.github/workflows/deploy.yml` reads all environment-specific
values from **GitHub repository Variables and Secrets**, so nothing sensitive is
committed to the repo. `.env.example` lists the same set of values for local dev.

### 1. Set GitHub Variables (non-sensitive)
**Settings → Secrets and variables → Actions → Variables tab → New repository variable**

| Name | Example value |
|---|---|
| `AWS_REGION` | `eu-west-1` |
| `S3_BUCKET` | `flask-demo-artifacts-abc123` |
| `CODEDEPLOY_APP` | `flask-demo-app` |
| `CODEDEPLOY_GROUP` | `flask-demo-dg` |

### 2. Set GitHub Secrets (sensitive)
**Settings → Secrets and variables → Actions → Secrets tab → New repository secret**

| Name | Example value |
|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActionsDeployRole` |

> The role ARN is stored as a secret because it embeds your AWS account ID.

### 3. How the workflow consumes them
```yaml
env:
  AWS_REGION: ${{ vars.AWS_REGION }}        # ← from Variables
  S3_BUCKET:  ${{ vars.S3_BUCKET }}
  ...
with:
  role-to-assume: ${{ secrets.AWS_ROLE_ARN }} # ← from Secrets
```

### 4. CLI alternative (if you prefer `gh`)
```bash
gh variable set AWS_REGION       --body "eu-west-1"
gh variable set S3_BUCKET        --body "flask-demo-artifacts-abc123"
gh variable set CODEDEPLOY_APP   --body "flask-demo-app"
gh variable set CODEDEPLOY_GROUP --body "flask-demo-dg"
gh secret   set AWS_ROLE_ARN     --body "arn:aws:iam::123456789012:role/GitHubActionsDeployRole"
```

After variables/secrets are in place, push to `main` and the workflow will run.
