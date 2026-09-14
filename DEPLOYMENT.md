# 🚀 Deployment Guide

Complete guide to deploy Desktop Browser to various platforms.

## Table of Contents
1. [Heroku](#heroku) (Easiest)
2. [Vercel](#vercel)
3. [Railway](#railway)
4. [Render](#render)
5. [AWS](#aws)
6. [DigitalOcean](#digitalocean)
7. [Docker](#docker)

---

## Heroku

### Prerequisites
- Heroku account (free tier available)
- Heroku CLI installed
- Git installed
- GitHub account

### Step-by-Step

1. **Create Heroku account**
   - Visit https://www.heroku.com/
   - Sign up (free tier available)

2. **Install Heroku CLI**
   ```bash
   # macOS
   brew tap heroku/brew && brew install heroku

   # Windows (using chocolatey)
   choco install heroku-cli

   # Linux
   curl https://cli-assets.heroku.com/install.sh | sh
   ```

3. **Login to Heroku**
   ```bash
   heroku login
   ```

4. **Create Heroku app**
   ```bash
   heroku create your-app-name
   ```

5. **Deploy**
   ```bash
   git push heroku main
   ```

6. **View logs**
   ```bash
   heroku logs --tail
   ```

7. **Open app**
   ```bash
   heroku open
   ```

### Configuration
Set environment variables:
```bash
heroku config:set NODE_ENV=production
heroku config:set RATE_LIMIT_MAX_REQUESTS=100
```

### Monitoring
- View logs: `heroku logs --tail`
- Check status: `heroku status`
- App metrics: Heroku dashboard

### Scaling
```bash
# Scale dyos
heroku ps:scale web=2

# View running dynos
heroku ps
```

**Cost**: Free tier (with limitations) or $7/month+

---

## Vercel

### Prerequisites
- Vercel account (free tier available)
- Vercel CLI installed
- Git installed

### Step-by-Step

1. **Create Vercel account**
   - Visit https://vercel.com/
   - Sign up (free tier available)

2. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

3. **Deploy**
   ```bash
   vercel
   ```

4. **Follow prompts**
   - Login to Vercel
   - Choose project settings
   - Deploy

5. **View deployment**
   - URL provided in terminal
   - Dashboard at https://vercel.com/dashboard

### Configuration
Create `vercel.json` (already included):
```json
{
  "version": 2,
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "server.js"
    }
  ]
}
```

### Auto-deployment from GitHub
1. Connect GitHub repository
2. Every push to main automatically deploys
3. View deployments in Vercel dashboard

**Cost**: Free tier (with limitations) or $20/month+

---

## Railway

### Prerequisites
- Railway account (free tier available)
- GitHub account
- Git installed

### Step-by-Step

1. **Create Railway account**
   - Visit https://railway.app/
   - Sign up with GitHub

2. **Connect repository**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose this repository

3. **Configure**
   - Railway auto-detects Node.js
   - Sets up automatically
   - Assigns domain

4. **Deploy**
   - Automatic deployment on push
   - View logs in dashboard

### Configuration
Set environment variables in Railway dashboard:
- `NODE_ENV`: production
- `PORT`: (auto)

**Cost**: Free tier ($5 credit/month) or pay-as-you-go

---

## Render

### Prerequisites
- Render account (free tier available)
- GitHub account
- Git installed

### Step-by-Step

1. **Create Render account**
   - Visit https://render.com/
   - Sign up with GitHub

2. **Create new Web Service**
   - Click "New +"
   - Select "Web Service"
   - Connect GitHub

3. **Configure**
   - Build command: `npm install`
   - Start command: `npm start`
   - Environment: Node
   - Instance: Free (if desired)

4. **Deploy**
   - Automatic deployment on push
   - URL provided

### Configuration
Set environment variables in Render dashboard

**Cost**: Free tier (with auto-sleep) or $7/month+

---

## AWS

### Prerequisites
- AWS account (free tier available)
- AWS CLI installed
- Local deployment knowledge

### Using Elastic Beanstalk (Easiest)

1. **Install EB CLI**
   ```bash
   pip install awsebcli --upgrade --user
   ```

2. **Initialize**
   ```bash
   eb init -p node.js-18 --region us-east-1
   ```

3. **Create environment**
   ```bash
   eb create desktop-browser-env
   ```

4. **Deploy**
   ```bash
   eb deploy
   ```

5. **View logs**
   ```bash
   eb logs
   ```

6. **Open app**
   ```bash
   eb open
   ```

### Using Lambda (Serverless)

1. **Create Lambda function**
   - Node.js 18.x runtime
   - Upload code
   - Add API Gateway trigger

2. **Configure**
   - Timeout: 30 seconds
   - Memory: 512 MB

3. **Deploy**
   - Function automatically deployed

**Cost**: Free tier (1M requests/month) or variable

---

## DigitalOcean

### Prerequisites
- DigitalOcean account
- SSH access to droplet
- Basic Linux knowledge

### Step-by-Step

1. **Create Droplet**
   - OS: Ubuntu 20.04 or later
   - Size: $4/month (basic)
   - Region: Choose closest to you

2. **SSH into droplet**
   ```bash
   ssh root@your_droplet_ip
   ```

3. **Update system**
   ```bash
   apt update && apt upgrade -y
   ```

4. **Install Node.js**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

5. **Install Git**
   ```bash
   apt install -y git
   ```

6. **Clone repository**
   ```bash
   git clone https://github.com/yourusername/desktop-browser.git
   cd desktop-browser
   ```

7. **Install dependencies**
   ```bash
   npm install --production
   ```

8. **Install PM2** (process manager)
   ```bash
   npm install -g pm2
   pm2 start server.js --name "desktop-browser"
   pm2 startup
   pm2 save
   ```

9. **Install and configure Nginx**
   ```bash
   apt install -y nginx
   ```

   Create `/etc/nginx/sites-available/desktop-browser`:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com www.your-domain.com;

       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

   Enable site:
   ```bash
   ln -s /etc/nginx/sites-available/desktop-browser /etc/nginx/sites-enabled/
   nginx -t
   systemctl restart nginx
   ```

10. **Setup SSL with Let's Encrypt**
    ```bash
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d your-domain.com
    ```

11. **Setup firewall**
    ```bash
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw enable
    ```

### Monitoring
```bash
# View app logs
pm2 logs desktop-browser

# Restart app
pm2 restart desktop-browser

# Monitor resources
pm2 monit
```

**Cost**: $4-6/month

---

## Docker

### Prerequisites
- Docker installed
- Docker Hub account (optional)
- Local Docker knowledge

### Step-by-Step

1. **Create Dockerfile** (already in project)

2. **Build image**
   ```bash
   docker build -t desktop-browser:latest .
   ```

3. **Run container locally**
   ```bash
   docker run -p 3000:3000 -e NODE_ENV=production desktop-browser:latest
   ```

4. **Test**
   - Open http://localhost:3000

5. **Push to Docker Hub**
   ```bash
   docker tag desktop-browser:latest yourusername/desktop-browser:latest
   docker push yourusername/desktop-browser:latest
   ```

6. **Deploy to cloud**
   - AWS ECS
   - Google Cloud Run
   - Azure Container Instances
   - DigitalOcean App Platform

### Docker Compose (for local development)

```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    restart: unless-stopped
```

Run:
```bash
docker-compose up
```

---

## Performance Comparison

| Platform | Cost | Startup | Scaling | Uptime | Best For |
|----------|------|---------|---------|--------|----------|
| **Heroku** | Free/$7 | ~30s | Easy | 99.95% | Small projects |
| **Vercel** | Free/$20 | ~10s | Auto | 99.99% | Quick deploy |
| **Railway** | Free/$5 | ~20s | Easy | 99.9% | Personal projects |
| **Render** | Free/$7 | ~30s | Easy | 99.5% | Hobby apps |
| **AWS** | Free/$20 | ~60s | Complex | 99.99% | Enterprise |
| **DigitalOcean** | $4/month | ~5m | Manual | 99.99% | Full control |
| **Docker** | Variable | ~5s | Custom | Variable | Any platform |

---

## Troubleshooting

### App Won't Start
```bash
# Check logs
heroku logs --tail
npm start

# Check Node version
node --version

# Clear cache
npm cache clean --force
rm -rf node_modules
npm install
```

### Slow Performance
- Check server logs
- Verify rate limiting isn't blocking
- Increase server resources
- Check network connectivity

### Memory Issues
- Increase available memory
- Monitor with process manager
- Check for memory leaks in logs
- Restart service daily (optional)

### HTTPS Not Working
- Verify SSL certificate
- Check Nginx configuration
- Renew certificate if expired
- Test with `certbot renew --dry-run`

---

## Security Checklist

Before deploying to production:

- [ ] Environment variables set securely
- [ ] .env file in .gitignore
- [ ] Rate limiting configured
- [ ] HTTPS/SSL enabled
- [ ] Firewall configured
- [ ] Security headers enabled
- [ ] Node.js updated
- [ ] Dependencies updated
- [ ] Secrets not in code
- [ ] Monitoring enabled

---

## Post-Deployment

1. **Setup monitoring**
   - Uptimerobot.com (free)
   - Statuspage.io
   - New Relic (optional)

2. **Setup backups**
   - Database backups
   - Log backups
   - Code backups

3. **Setup notifications**
   - Email alerts
   - Slack notifications
   - SMS alerts

4. **Setup CDN** (optional)
   - Cloudflare (free)
   - AWS CloudFront
   - Netlify

5. **Analytics** (optional)
   - Google Analytics
   - Mixpanel
   - Segment

---

## Maintenance

### Regular Tasks
- **Daily**: Monitor logs
- **Weekly**: Check security updates
- **Monthly**: Update dependencies
- **Quarterly**: Review and optimize code

### Update Dependencies
```bash
npm update
npm audit fix
```

### Update Node.js
```bash
# Check current version
node --version

# Update via package manager (platform-specific)
```

---

## Scaling

### Horizontal Scaling
- Add more servers
- Use load balancer
- Replicate database

### Vertical Scaling
- Increase server resources
- More memory
- More CPU
- SSD storage

### Database Scaling
- Add caching layer (Redis)
- Read replicas
- Sharding
- NoSQL options

---

## Cost Optimization

1. **Use free tiers when starting**
2. **Set up budget alerts**
3. **Monitor resource usage**
4. **Scale resources gradually**
5. **Use CDN for static assets**
6. **Enable compression**
7. **Set up caching**
8. **Use spot instances** (if available)

---

## Support

Deployment help:
- Platform-specific docs
- GitHub Issues
- Community forums
- Stack Overflow

---

**Choose the platform that best fits your needs!**

Last Updated: January 2024
