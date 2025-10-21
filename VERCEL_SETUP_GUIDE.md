# Vercel Setup Guide for mySahara Web

## ✅ Fixed Issues

The `vercel-build.sh` script has been updated to work correctly when the `my_sahara_app` folder is the repository root.

## 📋 Vercel Project Settings

When configuring your Vercel project, use these **exact settings**:

### Build & Development Settings

1. **Framework Preset**: `Other`

2. **Build Command**: 
   ```
   ./vercel-build.sh
   ```

3. **Output Directory**: 
   ```
   build/web
   ```
   ⚠️ **Important**: NOT `my_sahara_app/build/web` - just `build/web`

4. **Install Command**: 
   ```
   chmod +x vercel-build.sh
   ```

### Root Directory
- Leave as `.` (root) or leave blank
- Do NOT set it to `my_sahara_app`

## 🔧 Environment Variables

Add these in Vercel Dashboard → Settings → Environment Variables:

1. **SUPABASE_URL**
   - Value: Your Supabase project URL
   - Example: `https://xxxxx.supabase.co`

2. **SUPABASE_ANON_KEY**
   - Value: Your Supabase anonymous/public key
   - Example: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

3. **GOOGLE_CLIENT_ID** (for Google Sign-In)
   - Value: Your Google OAuth client ID for web
   - Example: `792639797251-xxxxx.apps.googleusercontent.com`

⚠️ **Note**: These environment variables need to match what's in your `.env` file locally.

## 📝 Files to Commit to GitHub

Make sure these files are in your GitHub repository:

```
my_sahara_app/
├── .env.example          (example env file, no secrets)
├── .vercelignore         ✅ Already created
├── vercel.json           ✅ Already created
├── vercel-build.sh       ✅ Fixed and updated
├── lib/                  (your Flutter code)
├── web/                  (web configuration)
│   ├── index.html        ✅ Updated with meta tags
│   └── manifest.json     ✅ Updated with branding
├── pubspec.yaml
└── ... (other Flutter files)
```

**DO NOT commit**:
- `.env` (contains secrets)
- `build/` directory (will be built by Vercel)
- `.dart_tool/`

## 🚀 Deployment Steps

### Step 1: Push to GitHub
```bash
cd my_sahara_app
git add vercel-build.sh vercel.json .vercelignore web/
git commit -m "Fix Vercel build configuration"
git push origin main
```

### Step 2: Redeploy on Vercel
Option A: Vercel will auto-deploy on push

Option B: Manual redeploy
1. Go to Vercel Dashboard
2. Select your project
3. Click "Deployments"
4. Click "Redeploy" on the latest deployment

### Step 3: Monitor Build
Watch the build logs for:
```
✅ --- Cloning Flutter SDK ---
✅ Flutter 3.x.x • channel stable
✅ --- Getting Flutter dependencies ---
✅ --- Building Flutter web app ---
✅ --- Build Complete ---
```

## 🐛 Troubleshooting

### Error: "cd: my_sahara_app: No such file or directory"
**Solution**: ✅ Fixed! The updated `vercel-build.sh` no longer tries to cd into my_sahara_app.

### Error: "flutter: command not found"
**Solution**: The build script clones Flutter SDK automatically. If this fails, check Vercel build logs for network issues.

### Error: "Could not find pubspec.yaml"
**Solution**: Make sure your GitHub repo has `pubspec.yaml` in the root (which it should if you uploaded the `my_sahara_app` folder).

### Build succeeds but app shows blank page
**Solutions**:
1. Check browser console for errors
2. Verify environment variables are set in Vercel
3. Check that `build/web/index.html` exists in deployment
4. Ensure base href is correct in `web/index.html`

### Environment variables not working
**Solution**: 
- Environment variables must be set in Vercel Dashboard
- They are NOT read from `.env` file during Vercel build
- After adding env vars, trigger a new deployment

## 📊 Expected Build Time

- Flutter SDK clone: ~2 minutes
- Dependencies download: ~30 seconds
- Web build: ~1-2 minutes
- **Total**: ~4 minutes

## ✅ Verification Checklist

After deployment succeeds:

- [ ] Navigate to your Vercel URL
- [ ] App loads without errors
- [ ] Can register/login
- [ ] Dashboard displays
- [ ] Can add medication
- [ ] Can add appointment
- [ ] Can switch language (English ↔ Bengali)
- [ ] Responsive on mobile/tablet/desktop

## 🔗 Useful Vercel Commands

```bash
# View deployment logs
vercel logs <deployment-url>

# List all deployments
vercel ls

# Remove a deployment
vercel rm <deployment-id>
```

## 📞 Next Steps After Successful Deployment

1. **Test thoroughly** on different browsers
2. **Set up custom domain** (optional)
3. **Enable Vercel Analytics** for insights
4. **Add to Google OAuth allowed origins**:
   - Go to Google Cloud Console
   - Add your Vercel domain to authorized JavaScript origins
5. **Update Supabase CORS settings** if needed

## 🎯 Success!

When everything works, you'll see:
- ✅ Build completes in ~4 minutes
- ✅ Deployment shows "Ready"
- ✅ Your app is live at `https://your-project.vercel.app`

---

**Last Updated**: October 21, 2025
**Status**: Ready for deployment with fixed configuration
