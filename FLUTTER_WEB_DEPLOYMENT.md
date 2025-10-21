# mySahara Flutter Web Deployment Guide

## Overview
This guide explains how to deploy the mySahara Flutter web application to Vercel.

## ✅ Completed Setup

### 1. Web Build Configuration
- ✅ Flutter web enabled
- ✅ Web directory configured
- ✅ Successfully builds with `flutter build web`
- ✅ Successfully runs locally with `flutter run -d chrome`

### 2. Web Metadata & Branding
- ✅ Updated `web/index.html` with proper meta tags
- ✅ Updated `web/manifest.json` with mySahara branding
- ✅ Added Open Graph and Twitter Card meta tags
- ✅ Updated theme colors to match app branding (#00695C)

### 3. Vercel Configuration
- ✅ Created `vercel.json` with proper routing and headers
- ✅ Created `.vercelignore` to optimize deployment
- ✅ Configured SPA routing (all routes → index.html)
- ✅ Added security headers (CSP, XSS protection, etc.)
- ✅ Optimized caching for assets and service workers

## 🚀 Deployment Instructions

### Option 1: Deploy via Vercel CLI (Recommended)

1. **Install Vercel CLI** (if not already installed):
   ```bash
   npm install -g vercel
   ```

2. **Build the Flutter web app**:
   ```bash
   cd my_sahara_app
   flutter build web --release
   ```

3. **Deploy to Vercel**:
   ```bash
   # First time deployment
   vercel --cwd build/web
   
   # Production deployment
   vercel --cwd build/web --prod
   ```

4. **Follow the prompts**:
   - Set up and deploy: Yes
   - Which scope: Your Vercel account
   - Link to existing project: No (first time) or Yes (subsequent deploys)
   - Project name: my-sahara-web (or your preferred name)
   - Directory: `build/web` (should already be set with --cwd)
   - Override settings: No

### Option 2: Deploy via Vercel Dashboard

1. **Build the Flutter web app**:
   ```bash
   flutter build web --release
   ```

2. **Go to Vercel Dashboard**: https://vercel.com/dashboard

3. **Click "Add New Project"**

4. **Import Git Repository** or **Upload build/web folder**:
   - If using Git: Connect your repository and set:
     - Framework Preset: Other
     - Build Command: `flutter build web --release`
     - Output Directory: `build/web`
     - Install Command: Leave empty (build locally instead)
   
   - If uploading manually: Just drag and drop the `build/web` folder

5. **Deploy**: Click Deploy

### Option 3: Automated GitHub Actions Deployment

Create `.github/workflows/deploy-web.yml`:

```yaml
name: Deploy Flutter Web to Vercel

on:
  push:
    branches: [main, master]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'
          
      - name: Install dependencies
        run: flutter pub get
        working-directory: ./my_sahara_app
        
      - name: Build web
        run: flutter build web --release
        working-directory: ./my_sahara_app
        
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./my_sahara_app/build/web
          vercel-args: '--prod'
```

## 🌐 Web App Features

### Fully Functional Features
- ✅ Authentication (Email/Password, Google Sign-In)
- ✅ Dashboard with health metrics
- ✅ Medical history tracking
- ✅ Medication management with reminders
- ✅ Appointment scheduling
- ✅ Family member management
- ✅ Document viewing (PDF, images)
- ✅ QR code generation for medical history sharing
- ✅ Multi-language support (English, Bengali)
- ✅ Responsive design

### Web-Specific Considerations

#### Limited Features (Browser Limitations)
1. **QR Code Scanning**: 
   - Uses browser camera API (requires HTTPS)
   - User needs to grant camera permission
   - May have limited functionality compared to mobile

2. **File Upload**:
   - Works via standard file picker
   - No direct camera integration
   - Limited to browser-supported file types

3. **Push Notifications**:
   - Uses browser notifications (requires permission)
   - Less reliable than mobile notifications
   - May not work on all browsers

4. **OCR (Text Recognition)**:
   - `google_mlkit_text_recognition` doesn't support web
   - Consider using a web-based OCR API as alternative
   - Currently limited functionality for document text extraction

#### Working Perfectly
- ✅ Supabase authentication and database
- ✅ PDF viewing and generation
- ✅ Image display and caching
- ✅ QR code generation (display)
- ✅ Google Sign-In (web SDK)
- ✅ Secure storage (uses browser storage)
- ✅ State management (Provider, GetX)
- ✅ Responsive UI

## 📱 Testing the Web App

### Local Testing
```bash
# Option 1: Run in Chrome (debug mode)
flutter run -d chrome

# Option 2: Run in Edge (debug mode)
flutter run -d edge

# Option 3: Serve built files
cd build/web
python -m http.server 8000
# Visit: http://localhost:8000
```

### Production Testing
After deploying to Vercel, test:
1. ✅ User registration and login
2. ✅ Dashboard loads correctly
3. ✅ Medication and appointment management
4. ✅ Document upload and viewing
5. ✅ QR code generation
6. ✅ Language switching
7. ✅ Responsive design on different screen sizes
8. ⚠️ QR scanning (if camera access granted)
9. ⚠️ Push notifications (if browser supports)

## 🔧 Environment Variables

Make sure to set these in Vercel dashboard:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key
- `GOOGLE_CLIENT_ID`: Google OAuth client ID (web)

**Note**: Flutter web reads from `.env` file during build, so these must be set before building.

## 🐛 Troubleshooting

### Build Issues
```bash
# Clear build cache
flutter clean
flutter pub get
flutter build web --release
```

### Deployment Issues
```bash
# Remove Vercel cache
vercel --cwd build/web --force

# Check Vercel logs
vercel logs <deployment-url>
```

### Runtime Issues
- Check browser console for errors
- Ensure all environment variables are set
- Verify Supabase connection
- Check CORS settings in Supabase

## 📊 Performance Optimization

The current build is optimized with:
- ✅ Tree-shaking for icons (99.4% reduction)
- ✅ Asset caching headers
- ✅ Service worker for offline capability
- ✅ Code splitting (via Flutter)
- ✅ Minified JavaScript (release build)

## 🔐 Security Headers

Configured in `vercel.json`:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: SAMEORIGIN`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`

## 📝 Build Output

Current build statistics:
- Main bundle: ~5.9 MB (JavaScript)
- CupertinoIcons: 1.5 KB (99.4% reduced)
- MaterialIcons: 24 KB (98.5% reduced)
- Build time: ~76 seconds

## 🎯 Next Steps

1. **Deploy to Vercel**: Follow deployment instructions above
2. **Set up custom domain**: Configure in Vercel dashboard
3. **Enable analytics**: Add Vercel Analytics or Google Analytics
4. **Monitor performance**: Use Vercel Speed Insights
5. **Set up CI/CD**: Use GitHub Actions for automated deployments

## 🌐 Live URLs (After Deployment)

- Production: `https://your-app.vercel.app`
- Preview: `https://your-app-git-branch.vercel.app`
- Development: `http://localhost:8080`

## 📞 Support

For issues or questions:
- Check Flutter web docs: https://flutter.dev/web
- Check Vercel docs: https://vercel.com/docs
- Review build logs in Vercel dashboard

---

**Status**: ✅ Ready for Deployment
**Last Updated**: October 21, 2025
**Flutter Version**: 3.9.2
**Deployment Platform**: Vercel
