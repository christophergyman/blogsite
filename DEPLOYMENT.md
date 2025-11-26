# Deployment Guide

This guide explains how to deploy the blogsite to a headless Debian server using Docker Compose with automated GitHub Actions deployment.

## Architecture

- **Build Container**: Multi-stage Docker build that compiles the Astro site
- **Web Server**: Nginx container serving static files from the build output
- **GitHub Actions**: Automated deployment workflow that triggers on main branch pushes
- **Deployment Method**: SSH-based deployment that pulls latest code and rebuilds containers

## Prerequisites

### On Your Debian Server

1. **Install Docker and Docker Compose**
   ```bash
   # Update package index
   sudo apt update
   
   # Install Docker
   sudo apt install -y docker.io docker-compose
   
   # Start and enable Docker
   sudo systemctl start docker
   sudo systemctl enable docker
   
   # Add your user to docker group (optional, to run without sudo)
   sudo usermod -aG docker $USER
   # Log out and back in for group changes to take effect
   ```

2. **Clone Your Repository**
   ```bash
   # Choose a location (e.g., /opt/blogsite or ~/blogsite)
   cd /opt
   sudo git clone <your-repo-url> blogsite
   cd blogsite
   
   # Or clone to your home directory
   cd ~
   git clone <your-repo-url> blogsite
   cd blogsite
   ```

3. **Configure Firewall**
   ```bash
   # Allow SSH (if not already allowed)
   sudo ufw allow 22/tcp
   
   # Allow HTTP
   sudo ufw allow 80/tcp
   
   # Allow HTTPS (for future SSL setup)
   sudo ufw allow 443/tcp
   
   # Enable firewall
   sudo ufw enable
   ```

4. **Find Your Server IP Addresses**
   ```bash
   # Private IP (for SSH from local network)
   hostname -I
   
   # Public IP (for domain DNS)
   curl ifconfig.me
   ```

## GitHub Secrets Configuration

Configure these secrets in your GitHub repository:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

### Required Secrets

- **`DEPLOY_HOST`**: Your server's IP address or hostname
  - Example: `192.168.1.100` or `your-server-hostname` (if you have hostname configured)
  
- **`DEPLOY_USER`**: SSH username for server access
  - Example: `root` or your username
  
- **`DEPLOY_SSH_KEY`**: Your private SSH key
  - On Mac, find it with: `cat ~/.ssh/id_rsa` or `cat ~/.ssh/id_ed25519`
  - Copy the entire key including `-----BEGIN` and `-----END` lines
  
- **`DEPLOY_PATH`**: Path on server where repository is cloned
  - Example: `/opt/blogsite` or `/home/username/blogsite`

## Domain Configuration

### DNS Setup

1. **Point Your Domain to Server**
   - Log into your domain registrar (e.g., Namecheap, Cloudflare, etc.)
   - Add an **A record**:
     - **Name**: `@` (or leave blank for root domain)
     - **Value**: Your server's public IP address
     - **TTL**: 3600 (or default)

2. **Optional: Add www Subdomain**
   - Add another **A record**:
     - **Name**: `www`
     - **Value**: Your server's public IP address

### Verify DNS Propagation

```bash
# Check if DNS is pointing to your server
dig cgym.dev
# or
nslookup cgym.dev
```

## Initial Deployment

### Manual Deployment (First Time)

1. **SSH into your server**
   ```bash
   ssh user@server-ip  # or ssh your-hostname if configured
   ```

2. **Navigate to repository**
   ```bash
   cd /opt/blogsite  # or wherever you cloned it
   ```

3. **Build and start containers**
   ```bash
   docker-compose up -d --build
   ```

4. **Check if containers are running**
   ```bash
   docker-compose ps
   ```

5. **View logs (if needed)**
   ```bash
   docker-compose logs -f
   ```

6. **Test the site**
   - Visit `http://your-server-ip` in your browser
   - Or visit `http://cgym.dev` once DNS propagates

## Automated Deployment

After setting up GitHub secrets, deployments will happen automatically:

1. **Push to main branch**
   ```bash
   git add .
   git commit -m "Update blog"
   git push origin main
   ```

2. **GitHub Actions will automatically:**
   - SSH into your server
   - Pull latest code
   - Rebuild and restart containers
   - Deploy the updated site

3. **Monitor deployment**
   - Go to **Actions** tab in your GitHub repository
   - Watch the deployment workflow run

## Server-Side Deployment Script (Optional)

If you prefer to deploy manually from the server, you can use the included `deploy.sh` script:

1. **Edit the script** to set the correct path:
   ```bash
   nano deploy.sh
   # Change: cd /path/to/your/blogsite
   # To: cd /opt/blogsite  # or your actual path
   ```

2. **Make it executable**
   ```bash
   chmod +x deploy.sh
   ```

3. **Run it**
   ```bash
   ./deploy.sh
   ```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs

# Check if port 80 is already in use
sudo netstat -tulpn | grep :80

# Stop any conflicting services
sudo systemctl stop nginx  # if system nginx is running
```

### Build fails
```bash
# Check Docker build logs
docker-compose build --no-cache

# Verify Dockerfile syntax
docker build -t test .
```

### GitHub Actions deployment fails
- Verify all secrets are set correctly
- Check SSH key has proper permissions on server
- Ensure `DEPLOY_PATH` is correct
- Test SSH connection manually: `ssh user@host`

### Site not accessible
- Check firewall: `sudo ufw status`
- Verify DNS: `dig cgym.dev`
- Check container is running: `docker-compose ps`
- View container logs: `docker-compose logs web`

### Permission issues
```bash
# If you get permission denied errors
sudo chown -R $USER:$USER /opt/blogsite
# or add your user to docker group (see Prerequisites)
```

## Adding SSL/HTTPS (Future)

To add HTTPS support, you can:

1. **Use Certbot with Nginx**
   - Run Certbot in a separate container
   - Mount certificates as volumes
   - Update nginx.conf to listen on port 443

2. **Use Traefik**
   - Add Traefik as reverse proxy
   - Automatic SSL certificate management

3. **Use Cloudflare**
   - Point domain through Cloudflare
   - Enable SSL/TLS encryption
   - Free SSL certificates

## Maintenance

### Update Docker Images
```bash
docker-compose pull
docker-compose up -d
```

### View Container Logs
```bash
docker-compose logs -f web
```

### Stop Containers
```bash
docker-compose down
```

### Restart Containers
```bash
docker-compose restart
```

### Clean Up
```bash
# Remove stopped containers and unused images
docker system prune -a
```

## Network Architecture

```
Internet 
  ↓
Domain (cgym.dev) 
  ↓
DNS A Record → Server Public IP
  ↓
Port 80 (HTTP)
  ↓
Docker Nginx Container
  ↓
Static Files (/usr/share/nginx/html)
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Astro Deployment Guide](https://docs.astro.build/en/guides/deploy/)
