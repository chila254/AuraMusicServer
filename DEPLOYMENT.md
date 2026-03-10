# AuraMusicServer - Deployment Guide

Choose your deployment option and follow the steps.

## Quick Comparison

| Platform | Cost | Difficulty | Uptime | Recommendation |
|----------|------|-----------|--------|-----------------|
| Railway | Free → $7/mo | ⭐ Easy | 99.9% | **Best for starting** |
| Render | Free → $7/mo | ⭐ Easy | 99.9% | **Good alternative** |
| Fly.io | Free → $5/mo | ⭐⭐ Medium | 99.95% | Good for scale |
| DigitalOcean | $4-6/mo | ⭐⭐⭐ Hard | 99.99% | Self-hosted control |
| Heroku | $7-50/mo | ⭐ Easy | 99.95% | Expensive |

---

## 🚀 Option 1: Railway (Recommended)

### Why Railway?
- Free tier generous enough for testing
- Auto-deploys when you push to GitHub
- Automatic HTTPS
- Excellent free-tier limits

### Steps

1. **Create GitHub repo:**
   ```bash
   cd AuraMusicServer
   git init
   git add .
   git commit -m "Initial commit: AuraMusicServer"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/AuraMusicServer.git
   git push -u origin main
   ```

2. **Sign up on railway.app:**
   - Go to https://railway.app
   - Click "Login with GitHub"
   - Authorize Railway

3. **Create new project:**
   - Click "Create Project"
   - Select "Deploy from GitHub repo"
   - Find and select your AuraMusicServer repo

4. **Configure:**
   - Railway should auto-detect Dockerfile
   - Click "Deploy"
   - Wait 2-3 minutes for build

5. **Get your URL:**
   - Go to Deployments tab
   - Copy the URL (something like `https://auramusic-production.up.railway.app`)
   - Your WebSocket URL is: `wss://auramusic-production.up.railway.app/ws`

6. **Test:**
   ```bash
   curl https://auramusic-production.up.railway.app/health
   ```

---

## 🚀 Option 2: Render.com

### Why Render?
- Auto-deploys from GitHub
- Free tier available
- Good performance
- Slightly simpler than Railway

### Steps

1. **Push to GitHub (same as Railway step 1)**

2. **Sign up on render.com:**
   - Go to https://render.com
   - Click "Sign Up"
   - Use GitHub to sign up

3. **Create new Web Service:**
   - Dashboard → New +
   - Select "Web Service"
   - Connect GitHub account
   - Select your AuraMusicServer repo

4. **Configure:**
   - Name: `auramusic-server`
   - Environment: `Docker`
   - Build Command: (leave empty, uses Dockerfile)
   - Start Command: (leave empty, uses CMD from Dockerfile)

5. **Add Environment Variable:**
   - Click "Advanced"
   - Add environment variable: `PORT=8080`

6. **Deploy:**
   - Click "Create Web Service"
   - Wait 3-5 minutes for build and deploy

7. **Get your URL:**
   - Copy from Service URL at top
   - Your WebSocket URL is: `wss://auramusic-server.onrender.com/ws`

---

## 🚀 Option 3: DigitalOcean (Self-hosted)

### Why Self-hosted?
- Full control
- Good for learning DevOps
- Predictable pricing
- Better for production

### Prerequisites
- DigitalOcean account ($5+ credit needed)
- SSH key pair
- Domain name (optional but recommended)

### Steps

1. **Create Droplet:**
   - DigitalOcean Dashboard → Create → Droplet
   - Choose: Ubuntu 24.04 LTS
   - Size: Basic $4-6/month (512MB RAM minimum)
   - Region: Closest to you
   - Authentication: SSH Key (or password)
   - Create

2. **SSH into your server:**
   ```bash
   ssh root@your_droplet_ip
   ```

3. **Install Docker:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker root
   ```

4. **Clone your repo:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/AuraMusicServer
   cd AuraMusicServer
   ```

5. **Deploy with Docker Compose:**
   ```bash
   docker-compose up -d
   ```

6. **Setup reverse proxy with Caddy (automatic HTTPS):**
   
   a) Install Caddy:
   ```bash
   apt-get install -y caddy
   ```

   b) Create Caddyfile:
   ```bash
   cat > /etc/caddy/Caddyfile << 'EOF'
   your-domain.com {
     reverse_proxy localhost:8080
   }
   EOF
   ```

   c) Start Caddy:
   ```bash
   systemctl restart caddy
   ```

7. **Verify:**
   ```bash
   curl https://your-domain.com/health
   ```

8. **View logs:**
   ```bash
   docker logs -f auramusic-server
   ```

### Monitoring on DigitalOcean

```bash
# Check if server is running
docker ps

# View logs
docker logs -f auramusic-server

# View resource usage
docker stats auramusic-server

# Restart if needed
docker restart auramusic-server

# Update code
cd AuraMusicServer
git pull
docker-compose up -d --build
```

---

## 🚀 Option 4: Fly.io

### Why Fly.io?
- Global deployment
- Good free tier
- Edge locations worldwide
- Great for global users

### Steps

1. **Install flyctl:**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login:**
   ```bash
   flyctl auth login
   ```

3. **Launch app:**
   ```bash
   cd AuraMusicServer
   flyctl launch
   ```
   - Name: `auramusic-server`
   - Select region closest to you
   - Skip database

4. **Deploy:**
   ```bash
   flyctl deploy
   ```

5. **Get your URL:**
   ```bash
   flyctl info
   ```
   Your WebSocket URL: `wss://auramusic-server.fly.dev/ws`

---

## 🌐 Setting Up Custom Domain

### For Railway/Render:

1. Buy domain on Namecheap/GoDaddy/etc
2. Go to your Railway/Render project settings
3. Add custom domain
4. Update DNS records (they'll show you how)
5. Wait 5-10 minutes for DNS propagation

### For DigitalOcean:

1. Buy domain
2. Point nameservers to DigitalOcean
3. Add domain to DigitalOcean DNS
4. Create A record pointing to droplet IP
5. Caddy will auto-generate HTTPS cert

---

## 📊 Monitoring & Maintenance

### Check Server Status

```bash
# All platforms
curl https://your-server-url.com/health
```

### View Logs

**Railway:**
```
Dashboard → Deployments → Logs
```

**Render:**
```
Service → Logs
```

**Docker (DigitalOcean):**
```bash
docker logs -f auramusic-server
```

### Scaling Up

- **Railway/Render:** Upgrade plan in dashboard
- **DigitalOcean:** Resize droplet or add second instance with load balancer
- **Fly.io:** Run `flyctl scale count=2`

### Backup

Session data is temporary. To persist data:

1. Edit `main.go` and uncomment state persistence
2. Add volume to docker-compose:
   ```yaml
   volumes:
     - ./data:/app/data
   ```
3. Redeploy

---

## 🔐 Production Checklist

- [ ] HTTPS/TLS enabled
- [ ] Health endpoint working
- [ ] Logs accessible
- [ ] Monitoring set up
- [ ] Backup strategy defined
- [ ] Domain name configured
- [ ] Auto-restart enabled
- [ ] Rate limiting considered (if needed)

---

## 💰 Cost Summary (Monthly)

| Platform | Free Tier | Paid Tier | Recommendation |
|----------|-----------|-----------|-----------------|
| Railway | Generous | $7/mo | ⭐⭐⭐⭐⭐ |
| Render | Good | $7/mo | ⭐⭐⭐⭐ |
| Fly.io | Good | $5/mo | ⭐⭐⭐⭐ |
| DigitalOcean | None | $4-6/mo | ⭐⭐⭐⭐ |
| Heroku | Ended | $7-50/mo | Not recommended |

For a new project: **Start with Railway or Render free tier**
For production users: **Move to DigitalOcean or Fly.io**

---

## ❌ Troubleshooting Deployment

### "Docker build fails"
- Check Dockerfile exists
- Ensure go.mod/go.sum are valid
- Try building locally first: `docker build -t auramusic-server .`

### "Server won't start"
- Check logs for errors
- Verify PORT environment variable
- Ensure no other service on that port

### "WebSocket connection fails"
- Check if `wss://` (HTTPS) works
- Verify server is running: `curl https://your-url/health`
- Check firewall allows connections

### "High latency after deployment"
- Server might be far from users
- Choose deployment region closer to your users
- Check server resource usage

---

## 📞 Support Links

- Railway Help: https://docs.railway.app
- Render Docs: https://render.com/docs
- Fly.io Docs: https://fly.io/docs
- DigitalOcean Tutorials: https://www.digitalocean.com/community
- Docker Docs: https://docs.docker.com

---

**Ready to deploy? Pick an option above and follow the steps!** 🚀
