import axios, { AxiosInstance } from 'axios';

export interface VaultClientOptions {
  vaultAddr: string;
  vaultToken: string;
}

export interface VaultHealth {
  initialized: boolean;
  sealed: boolean;
  standby: boolean;
  performance_standby: boolean;
  replication_performance_mode: string;
  replication_dr_mode: string;
  server_time_utc: number;
  version: string;
  cluster_name: string;
  cluster_id: string;
}

export class VaultClient {
  private client: AxiosInstance;
  private token: string;

  constructor(options: VaultClientOptions) {
    this.token = options.vaultToken;
    this.client = axios.create({
      baseURL: options.vaultAddr,
      headers: {
        'X-Vault-Token': this.token,
        'Content-Type': 'application/json',
      },
    });
  }

  async health(): Promise<VaultHealth> {
    const response = await this.client.get('/v1/sys/health');
    return response.data;
  }

  async getSecret(path: string): Promise<any> {
    const response = await this.client.get(`/v1/secret/data/${path}`);
    return response.data.data.data;
  }

  async listSecrets(path: string = ''): Promise<string[]> {
    const response = await this.client.get(`/v1/secret/metadata/${path}?list=true`);
    return response.data.data.keys || [];
  }

  async putSecret(path: string, data: any): Promise<void> {
    await this.client.put(`/v1/secret/data/${path}`, { data });
  }

  async deleteSecret(path: string): Promise<void> {
    await this.client.delete(`/v1/secret/metadata/${path}`);
  }

  async encrypt(keyName: string, data: string): Promise<string> {
    const response = await this.client.post(`/v1/transit/encrypt/${keyName}`, {
      plaintext: Buffer.from(data).toString('base64'),
    });
    return response.data.data.ciphertext;
  }

  async decrypt(keyName: string, ciphertext: string): Promise<string> {
    const response = await this.client.post(`/v1/transit/decrypt/${keyName}`, {
      ciphertext,
    });
    return Buffer.from(response.data.data.plaintext, 'base64').toString();
  }

  async createTransitKey(keyName: string): Promise<void> {
    await this.client.post(`/v1/transit/keys/${keyName}`, {
      type: 'aes256-gcm96',
    });
  }

  async rotateTransitKey(keyName: string): Promise<void> {
    await this.client.post(`/v1/transit/keys/${keyName}/rotate`);
  }

  async getDatabaseCredentials(role: string): Promise<any> {
    const response = await this.client.get(`/v1/database/creds/${role}`);
    return response.data.data;
  }

  async renewLease(leaseId: string): Promise<any> {
    const response = await this.client.put(`/v1/sys/leases/renew`, {
      lease_id: leaseId,
    });
    return response.data;
  }

  async revokeLease(leaseId: string): Promise<void> {
    await this.client.put(`/v1/sys/leases/revoke`, {
      lease_id: leaseId,
    });
  }
}
