#!/bin/bash

# Script to upload AIc files to Beget hosting
# SSH credentials: konans6z_aic@konans6z.beget.tech (password: xnZhqMf!60vz)

echo "🚀 Uploading AIc files to konans6z.beget.tech..."
echo "📋 You will be prompted for password: xnZhqMf!60vz"

# Create project directory on server
echo "\n0️⃣ Creating project directory..."
ssh konans6z_aic@konans6z.beget.tech "mkdir -p ~/aic-app && echo 'Directory created: ~/aic-app'"

# Upload main server files to project directory
echo "\n1️⃣ Uploading main server files..."
scp server-beget.js konans6z_aic@konans6z.beget.tech:~/aic-app/server-beget.js
scp package-beget.json konans6z_aic@konans6z.beget.tech:~/aic-app/package.json
scp .env.beget konans6z_aic@konans6z.beget.tech:~/aic-app/.env

# Upload database schema
echo "\n2️⃣ Uploading database schema..."
scp create-mysql-schema.sql konans6z_aic@konans6z.beget.tech:~/aic-app/

# Upload documentation
echo "\n3️⃣ Uploading documentation..."
scp DEPLOY-PLAN-FINAL.md konans6z_aic@konans6z.beget.tech:~/aic-app/

echo "\n✅ Files uploaded to ~/aic-app/! Now connect via SSH:"
echo "ssh konans6z_aic@konans6z.beget.tech"
echo "Password: xnZhqMf!60vz"

echo "\n📝 Next steps on server:"
echo "cd ~/aic-app"
echo "npm install --production"
echo "node server-beget.js &"
echo "\n🧪 Test endpoints:"
echo "curl https://konans6z.beget.tech/health"