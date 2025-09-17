import { createRouter } from '@backstage/backend-common';
import { Config } from '@backstage/config';
import { Router } from 'express';
import { VaultClient } from './vault-client';

export interface VaultPluginOptions {
  config: Config;
}

export function createVaultPlugin(options: VaultPluginOptions): Router {
  const { config } = options;
  const router = Router();
  
  const vaultClient = new VaultClient({
    vaultAddr: config.getString('vault.addr'),
    vaultToken: config.getString('vault.token'),
  });

  // Health check endpoint
  router.get('/health', async (req, res) => {
    try {
      const health = await vaultClient.health();
      res.json(health);
    } catch (error) {
      res.status(500).json({ error: 'Vault health check failed' });
    }
  });

  // Get secret endpoint
  router.get('/secrets/:path(*)', async (req, res) => {
    try {
      const { path } = req.params;
      const secret = await vaultClient.getSecret(path);
      res.json(secret);
    } catch (error) {
      res.status(500).json({ error: 'Failed to retrieve secret' });
    }
  });

  // List secrets endpoint
  router.get('/secrets', async (req, res) => {
    try {
      const secrets = await vaultClient.listSecrets();
      res.json(secrets);
    } catch (error) {
      res.status(500).json({ error: 'Failed to list secrets' });
    }
  });

  // Encrypt data endpoint
  router.post('/encrypt', async (req, res) => {
    try {
      const { data, keyName } = req.body;
      const encrypted = await vaultClient.encrypt(keyName, data);
      res.json({ encrypted });
    } catch (error) {
      res.status(500).json({ error: 'Failed to encrypt data' });
    }
  });

  // Decrypt data endpoint
  router.post('/decrypt', async (req, res) => {
    try {
      const { data, keyName } = req.body;
      const decrypted = await vaultClient.decrypt(keyName, data);
      res.json({ decrypted });
    } catch (error) {
      res.status(500).json({ error: 'Failed to decrypt data' });
    }
  });

  return router;
}
