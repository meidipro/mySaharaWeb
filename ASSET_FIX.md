# Asset Directory Fix for Vercel Deployment

## Problem
Build failed with errors:
```
Error: unable to find directory entry in pubspec.yaml: /vercel/path0/assets/images/
Error: unable to find directory entry in pubspec.yaml: /vercel/path0/assets/icons/
Error: No file or variants found for asset: .env
```

## Root Cause
1. `assets/images/` and `assets/icons/` directories existed but were **empty**
2. `.env` file was referenced in `pubspec.yaml` but excluded in `.vercelignore`

## Solution

### 1. Added Placeholder Files
Created `.gitkeep` files in empty asset directories so they're not empty:
- `assets/images/.gitkeep`
- `assets/icons/.gitkeep`

### 2. Removed .env from pubspec.yaml
Changed from:
```yaml
assets:
  - assets/images/
  - assets/icons/
  - .env  ❌ Excluded by .vercelignore
```

To:
```yaml
assets:
  - assets/images/
  - assets/icons/
  # .env should be set via Vercel environment variables ✅
```

## Important: Environment Variables

Your app should load environment variables at runtime, NOT bundle them in the build.

### For Local Development
Keep your `.env` file locally with:
```
SECRET_KEY=...
BACKEND_URL=https://mysahara.onrender.com
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

### For Vercel Production
Set these in Vercel Dashboard → Settings → Environment Variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `BACKEND_URL`
- Any other app-specific variables

## Files Changed
1. ✅ `assets/images/.gitkeep` - Created
2. ✅ `assets/icons/.gitkeep` - Created
3. ✅ `pubspec.yaml` - Removed .env from assets

## Next Steps

1. **Commit and push:**
   ```bash
   git add assets/ pubspec.yaml ASSET_FIX.md
   git commit -m "Fix: Add asset placeholders and remove .env from bundle"
   git push origin main
   ```

2. **Set Vercel environment variables** (if not already done):
   - Go to Vercel Dashboard → Your Project → Settings → Environment Variables
   - Add all required variables

3. **Wait for build** - Should complete successfully now!

---

**Status**: ✅ FIXED
**Date**: October 21, 2025
