# Gemini API Setup Guide

## Overview

Bodii uses Google's Gemini API to provide AI-powered diet comments and recommendations. This guide will help you configure your API key.

## Prerequisites

- Google account
- Internet connection

## Step 1: Get Your Gemini API Key

1. Visit https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click **"Get API Key"** or **"Create API Key"**
4. Copy the generated API key (format: `AIza...`)

## Step 2: Configure Info.plist

### For Local Development

1. Locate your `Bodii/Info.plist` file in Xcode
2. Add a new row with the following:
   - **Key**: `GEMINI_API_KEY`
   - **Type**: String
   - **Value**: `[Your API key from Step 1]`

**XML Format** (if editing manually):
```xml
<key>GEMINI_API_KEY</key>
<string>AIza_your_actual_api_key_here</string>
```

### For CI/CD

Set environment variable:
```bash
export GEMINI_API_KEY="AIza_your_actual_api_key_here"
xcodebuild build ...
```

The app will automatically read from environment variables if Info.plist key is not found.

## Step 3: Verify Configuration

1. Build and run the app in Xcode
2. Navigate to **Diet** tab
3. Add some food to any meal
4. Tap the **"AI"** button (purple badge with sparkles icon)
5. You should see AI-generated diet comment loading

### Troubleshooting

**Problem**: "⚠️ Gemini API 키가 Info.plist에 설정되지 않았습니다!"

**Solution**:
- Check that `GEMINI_API_KEY` is spelled correctly in Info.plist
- Verify the API key value is not empty
- Clean build folder (Cmd+Shift+K) and rebuild

**Problem**: "API 인증에 실패했습니다"

**Solution**:
- Verify your API key is valid at https://makersuite.google.com/app/apikey
- Check that you copied the entire key (starts with "AIza")
- Regenerate a new API key if needed

**Problem**: "요청 횟수 제한(분당 15회)을 초과했습니다"

**Solution**:
- Wait 1 minute before trying again
- This is expected behavior for the free tier (15 requests/minute)
- Comments are cached for 24 hours to reduce API calls

## Security Best Practices

### ✅ DO:
- Keep your API key in Info.plist (which is gitignored)
- Use environment variables for CI/CD
- Regenerate your key if accidentally exposed

### ❌ DON'T:
- Commit Info.plist with real API keys to Git
- Share your API key publicly
- Hardcode API keys in source code

## Rate Limits

**Free Tier**:
- 15 requests per minute (RPM)
- 1,500 requests per day (RPD)

**How Bodii Optimizes Usage**:
- ✅ Client-side rate limiting (respects 15 RPM)
- ✅ 24-hour caching (avoids redundant calls)
- ✅ Cache-first strategy (only calls API when needed)

For most users, the free tier is sufficient (one comment per meal = ~12 requests/day).

## API Key Management

### Rotating Your Key

1. Generate new key at https://makersuite.google.com/app/apikey
2. Update Info.plist with new key
3. Delete old key from Google AI Studio

### Monitoring Usage

Visit https://makersuite.google.com/app/apikey to see:
- Requests this month
- Rate limit status
- API key status

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify API key at https://makersuite.google.com/app/apikey
3. Check Xcode console for detailed error messages

## References

- [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
- [Get API Key](https://makersuite.google.com/app/apikey)
- [Gemini API Quickstart](https://ai.google.dev/gemini-api/docs/quickstart)
