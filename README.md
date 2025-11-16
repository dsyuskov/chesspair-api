## Description


## Project setup

```bash
$ yarn install
```

## Compile and run the project

```bash
# development
$ yarn run start

# watch mode
$ yarn run start:dev

# production mode
$ yarn run start:prod
```

## Run tests

```bash
# unit tests
$ yarn run test

# e2e tests
$ yarn run test:e2e

# test coverage
$ yarn run test:cov
```
## Docker / Deployment

This repository contains a Dockerfile for packaging the application for deployment on a VDS or other host.

Build image locally:

```bash
# Build image (tag as you like)
docker build -t chesspair-api:latest .
```

Run container:

```bash
# Run in background mapping host port 3000 -> container 3000
docker run -d -p 3000:3000 --name chesspair-api --restart unless-stopped chesspair-api:latest
```

You can also use Docker Compose:

```bash
docker compose up -d --build
```

Notes:
- The Dockerfile uses a multi-stage build: dependencies are installed and the app is built in the builder stage; the final image contains the compiled `dist` and `node_modules`.
- Provide runtime environment variables using `-e` or in Compose. Copy `.env.example` to `.env` locally if needed (but do not commit `.env`).

## Automated Deployment with GitHub Actions

The project includes a complete CI/CD pipeline (`.github/workflows/ci-cd-deploy.yml`) that:

1. **Tests** on every push/PR (linting, tests, build)
2. **Builds & Pushes** Docker image to GitHub Container Registry on master branch
3. **Deploys** automatically to your VDS via SSH

### VDS Deployment Setup

#### Prerequisites

- Docker and docker-compose installed on your VDS
- SSH access to your VDS
- GitHub repository with SSH key pair configured

#### Step 1: Generate SSH Key Pair on Your VDS

```bash
# On your VDS, generate an SSH key (if you don't have one)
ssh-keygen -t ed25519 -f ~/.ssh/github-deploy -C "github-actions"

# Copy public key to authorized_keys
cat ~/.ssh/github-deploy.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### Step 2: Add GitHub Secrets

In your GitHub repository, go to **Settings → Secrets and variables → Actions** and add:

| Secret | Description | Example |
|--------|-------------|---------|
| `VDS_HOST` | VDS IP or hostname | `123.45.67.89` or `api.example.com` |
| `VDS_USER` | SSH username | `root` or `deploy` |
| `VDS_SSH_KEY` | Private SSH key (paste full content) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VDS_APP_PATH` | App directory on VDS | `/home/deploy/chesspair-api` |

#### Step 3: Prepare Application Directory on VDS

```bash
# SSH into your VDS
ssh -i ~/.ssh/github-deploy deploy@YOUR_VDS_IP

# Create app directory
mkdir -p /home/deploy/chesspair-api
cd /home/deploy/chesspair-api

# Create .env file (if needed)
cat > .env << 'EOF'
NODE_ENV=production
PORT=3000
EOF
```

#### Step 4: Deploy

Simply push to the master branch and GitHub Actions will automatically:
1. Run tests
2. Build Docker image
3. Push to GitHub Container Registry
4. SSH into VDS
5. Pull and run the latest image with docker-compose

```bash
git add .
git commit -m "Deploy to production"
git push origin master
```

#### Monitoring Deployment

- View deployment status in GitHub: **Actions tab → CI/CD - Build, Test & Deploy**
- SSH into your VDS to check container status:

```bash
ssh deploy@YOUR_VDS_IP
docker compose ps
docker compose logs -f
```

#### Troubleshooting

**Deployment fails with SSH auth error:**
- Verify VDS_SSH_KEY is the full private key content (including BEGIN/END lines)
- Ensure VDS_USER has correct username
- Check firewall rules allow SSH from GitHub Actions IPs

**Container won't start:**
```bash
docker compose logs
docker compose ps
```

**Port 3000 not responding:**
- Check if port is open: `curl http://localhost:3000/health`
- Check firewall on VDS: `sudo ufw allow 3000`
- View logs: `docker compose logs chesspair-api`
