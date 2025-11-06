# GitHub Integration Setup Guide

This guide will help you set up GitHub integration for Backstage catalog auto-discovery.

## What This Enables

With GitHub integration configured, Backstage can:
- ✅ Automatically discover and register services from GitHub repositories
- ✅ Pull `catalog-info.yaml` files directly from GitHub
- ✅ Keep catalog entries in sync with your repositories
- ✅ Access repository metadata, README files, and more

## Step 1: Create a GitHub Personal Access Token (PAT)

1. **Go to GitHub Settings**
   - Visit: https://github.com/settings/tokens
   - Or: GitHub Profile → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token**
   - Click "Generate new token" → "Generate new token (classic)"
   - Give it a descriptive name: `Backstage Catalog Discovery`

3. **Select Required Scopes**
   - For **public repositories only**: Check `public_repo`
   - For **private repositories**: Check `repo` (includes all repo permissions)
   - For **reading repository contents**: Check `read:org` (if using GitHub organizations)

4. **Generate and Copy Token**
   - Click "Generate token"
   - **IMPORTANT**: Copy the token immediately - you won't be able to see it again!
   - It will look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 2: Configure Backstage

### Option A: Using Environment Variables (Recommended)

1. **Create `.env` file** in `Backstage-ULP/` directory:
   ```bash
   cd Backstage-ULP
   cp .env.example .env
   ```

2. **Edit `.env` file** and add your token:
   ```bash
   GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

3. **Restart Backstage**:
   ```bash
   cd ..
   ./start-ulp.sh stop
   ./start-ulp.sh backstage
   ```

### Option B: Export Environment Variable

If you prefer to export it in your shell:
```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
cd Backstage-ULP
docker compose -f docker-compose-simple.yml restart backstage
```

## Step 3: Add GitHub Catalog Locations

The configuration is already set up in `app-config.local.yaml` with an example for the Python app:

```yaml
catalog:
  locations:
    # Python App from GitHub
    - type: url
      target: https://github.com/pdaxh/python-app/blob/main/catalog-info.yaml
      rules:
        - allow: [Component, API]
```

### Adding More Repositories

To add more repositories, add entries to the `catalog.locations` section:

```yaml
catalog:
  locations:
    # Your service repository
    - type: url
      target: https://github.com/your-org/your-service/blob/main/catalog-info.yaml
      rules:
        - allow: [Component, API]
    
    # Another service
    - type: url
      target: https://github.com/your-org/another-service/blob/main/catalog-info.yaml
      rules:
        - allow: [Component, System]
```

**Note**: The `catalog-info.yaml` file must exist in the repository at the specified path.

## Step 4: Verify Integration

1. **Check Backstage Logs**:
   ```bash
   cd Backstage-ULP
   docker compose -f docker-compose-simple.yml logs backstage | grep -i github
   ```

2. **Check Catalog in Backstage UI**:
   - Open http://localhost:7007
   - Go to "Catalog" in the sidebar
   - You should see your Python App component
   - Check if it shows the GitHub repository link

3. **Test Auto-Discovery**:
   - Go to "Catalog" → "Create Component"
   - Select "Register Existing Component"
   - Enter a GitHub URL like: `https://github.com/pdaxh/python-app`
   - Backstage should automatically discover the `catalog-info.yaml` file

## Troubleshooting

### Token Not Working

**Error**: `401 Unauthorized` or `403 Forbidden`

**Solutions**:
- Verify the token is correct (no extra spaces)
- Check token hasn't expired
- Ensure token has required scopes (`repo` or `public_repo`)
- For private repos, make sure `repo` scope is enabled

### Catalog Not Updating

**Issue**: Changes in GitHub not reflected in Backstage

**Solutions**:
- Restart Backstage to trigger refresh
- Check Backstage logs for errors
- Verify the `catalog-info.yaml` path is correct
- Ensure the file exists in the repository

### Rate Limiting

**Error**: `403 API rate limit exceeded`

**Solutions**:
- GitHub API has rate limits (60 requests/hour for unauthenticated, 5000/hour for authenticated)
- Using a PAT increases your rate limit significantly
- If you hit limits, wait a bit and try again

## Advanced: Using GitHub Organizations

To discover all repositories in an organization:

```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/your-org/.github/blob/main/catalog-info.yaml
```

Or use the GitHub discovery feature (requires additional configuration):
- See: https://backstage.io/docs/integrations/github/discovery

## Security Best Practices

1. **Use Fine-Grained Tokens** (if available):
   - GitHub now supports fine-grained personal access tokens
   - More secure than classic tokens
   - Can limit access to specific repositories

2. **Rotate Tokens Regularly**:
   - Update tokens every 90 days
   - Revoke old tokens when creating new ones

3. **Use Environment Variables**:
   - Never commit tokens to git
   - Use `.env` file (already in `.gitignore`)
   - For production, use secret management (Kubernetes secrets, etc.)

4. **Limit Token Scopes**:
   - Only grant minimum required permissions
   - For catalog discovery, `public_repo` or `repo` is usually sufficient

## Next Steps

Once GitHub integration is working:

1. ✅ **Add More Services**: Register all your microservices
2. ✅ **Set Up Auto-Discovery**: Configure organization-wide discovery
3. ✅ **Enable GitHub OAuth**: Let users sign in with GitHub
4. ✅ **Add CI/CD Integration**: Auto-update catalog on deployments

## References

- [Backstage GitHub Integration Docs](https://backstage.io/docs/integrations/github/locations)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Backstage Catalog Locations](https://backstage.io/docs/features/software-catalog/descriptor-format#catalog-locations)

