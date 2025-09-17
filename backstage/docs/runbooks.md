# Operational Runbooks

This section contains operational procedures and troubleshooting guides for the ULP platform.

## Table of Contents

- [Incident Response](#incident-response)
- [Deployment Procedures](#deployment-procedures)
- [Monitoring & Alerting](#monitoring--alerting)
- [Database Operations](#database-operations)
- [Security Procedures](#security-procedures)
- [Backup & Recovery](#backup--recovery)
- [Performance Tuning](#performance-tuning)

## Incident Response

### Severity Levels

| Level | Description | Response Time | Escalation |
|-------|-------------|---------------|------------|
| P1 | Critical - Service down | 15 minutes | Immediate |
| P2 | High - Major functionality affected | 1 hour | 2 hours |
| P3 | Medium - Minor functionality affected | 4 hours | 8 hours |
| P4 | Low - Cosmetic issues | 24 hours | 48 hours |

### Incident Response Process

#### 1. Initial Response (0-15 minutes)

1. **Acknowledge the incident**
   ```bash
   # Check service status
   kubectl get pods -n backstage
   kubectl get pods -n dev-portal
   
   # Check logs
   kubectl logs -f deployment/backstage -n backstage
   ```

2. **Assess impact**
   - How many users are affected?
   - What functionality is impacted?
   - Is there a workaround available?

3. **Communicate**
   - Update incident channel
   - Notify stakeholders
   - Create incident ticket

#### 2. Investigation (15-60 minutes)

1. **Gather information**
   ```bash
   # Check resource usage
   kubectl top pods -n backstage
   kubectl top nodes
   
   # Check events
   kubectl get events --sort-by=.metadata.creationTimestamp
   
   # Check service endpoints
   kubectl get svc -n backstage
   ```

2. **Identify root cause**
   - Check application logs
   - Review system metrics
   - Analyze recent changes

3. **Implement temporary fix**
   - Scale up resources if needed
   - Restart failing services
   - Enable maintenance mode

#### 3. Resolution (1-4 hours)

1. **Implement permanent fix**
   - Deploy hotfix if available
   - Rollback to previous version
   - Apply configuration changes

2. **Verify resolution**
   - Test functionality
   - Monitor metrics
   - Confirm with users

3. **Post-incident review**
   - Document lessons learned
   - Update runbooks
   - Schedule follow-up

### Common Incidents

#### Service Unavailable (503 Error)

**Symptoms**:
- Users cannot access the application
- HTTP 503 responses
- High error rates in monitoring

**Investigation**:
```bash
# Check pod status
kubectl get pods -n backstage

# Check service endpoints
kubectl get endpoints -n backstage

# Check ingress status
kubectl get ingress -n backstage
```

**Resolution**:
```bash
# Restart deployment
kubectl rollout restart deployment/backstage -n backstage

# Scale up if needed
kubectl scale deployment/backstage --replicas=3 -n backstage

# Check resource limits
kubectl describe pod <pod-name> -n backstage
```

#### Database Connection Issues

**Symptoms**:
- Database connection timeouts
- High database CPU usage
- Connection pool exhaustion

**Investigation**:
```bash
# Check database pods
kubectl get pods -n backstage | grep postgres

# Check database logs
kubectl logs -f deployment/postgres -n backstage

# Check connection count
kubectl exec -it <postgres-pod> -n backstage -- psql -c "SELECT count(*) FROM pg_stat_activity;"
```

**Resolution**:
```bash
# Restart database
kubectl rollout restart deployment/postgres -n backstage

# Increase connection limits
kubectl patch deployment/postgres -n backstage -p '{"spec":{"template":{"spec":{"containers":[{"name":"postgres","env":[{"name":"MAX_CONNECTIONS","value":"200"}]}]}}}}'
```

## Deployment Procedures

### Standard Deployment

#### 1. Pre-deployment Checks

```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Check resource availability
kubectl top nodes
kubectl describe nodes

# Verify ArgoCD sync status
kubectl get applications -n argocd
```

#### 2. Deploy to Development

```bash
# Trigger ArgoCD sync
argocd app sync backstage-dev

# Monitor deployment
kubectl rollout status deployment/backstage -n dev-portal

# Verify deployment
kubectl get pods -n dev-portal
kubectl logs -f deployment/backstage -n dev-portal
```

#### 3. Deploy to Production

```bash
# Sync production application
argocd app sync backstage-kustomize

# Monitor deployment
kubectl rollout status deployment/backstage -n backstage

# Verify deployment
kubectl get pods -n backstage
kubectl logs -f deployment/backstage -n backstage
```

### Rollback Procedures

#### Quick Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/backstage -n backstage

# Verify rollback
kubectl rollout status deployment/backstage -n backstage
kubectl get pods -n backstage
```

#### Specific Version Rollback

```bash
# List rollout history
kubectl rollout history deployment/backstage -n backstage

# Rollback to specific revision
kubectl rollout undo deployment/backstage --to-revision=2 -n backstage
```

## Monitoring & Alerting

### Key Metrics to Monitor

#### Application Metrics
- Request rate (RPS)
- Response time (latency)
- Error rate (4xx, 5xx)
- Active users

#### Infrastructure Metrics
- CPU utilization
- Memory usage
- Disk I/O
- Network traffic

#### Database Metrics
- Connection count
- Query performance
- Lock contention
- Replication lag

### Alert Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| CPU Usage | 70% | 85% | Scale up |
| Memory Usage | 80% | 90% | Scale up |
| Error Rate | 5% | 10% | Investigate |
| Response Time | 500ms | 1s | Investigate |
| Database Connections | 80% | 95% | Scale up |

### Monitoring Commands

```bash
# Check pod resource usage
kubectl top pods -n backstage

# Check node resource usage
kubectl top nodes

# Check service endpoints
kubectl get endpoints -n backstage

# Check ingress status
kubectl get ingress -n backstage
```

## Database Operations

### Backup Procedures

#### Daily Backup

```bash
# Create database backup
kubectl exec -it <postgres-pod> -n backstage -- pg_dump -U backstage backstage > backup-$(date +%Y%m%d).sql

# Verify backup
ls -la backup-*.sql
```

#### Restore from Backup

```bash
# Restore database
kubectl exec -i <postgres-pod> -n backstage -- psql -U backstage backstage < backup-20240101.sql

# Verify restore
kubectl exec -it <postgres-pod> -n backstage -- psql -U backstage -c "SELECT count(*) FROM users;"
```

### Database Maintenance

#### Vacuum and Analyze

```bash
# Run vacuum
kubectl exec -it <postgres-pod> -n backstage -- psql -U backstage -c "VACUUM ANALYZE;"

# Check table sizes
kubectl exec -it <postgres-pod> -n backstage -- psql -U backstage -c "SELECT schemaname,tablename,pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

## Security Procedures

### Security Incident Response

#### 1. Immediate Actions

1. **Isolate affected systems**
   ```bash
   # Block suspicious IPs
   kubectl patch networkpolicy/backstage-netpol -n backstage -p '{"spec":{"ingress":[{"from":[{"ipBlock":{"cidr":"0.0.0.0/0","except":["<suspicious-ip>/32"]}}]}]}}'
   ```

2. **Preserve evidence**
   ```bash
   # Collect logs
   kubectl logs --previous deployment/backstage -n backstage > security-incident-logs.txt
   
   # Export audit logs
   kubectl get events --all-namespaces > security-events.txt
   ```

3. **Notify security team**
   - Contact security team immediately
   - Document all actions taken
   - Preserve evidence for investigation

#### 2. Investigation

1. **Analyze logs**
   - Review access logs
   - Check for unusual patterns
   - Identify attack vectors

2. **Assess damage**
   - Determine data exposure
   - Check for unauthorized access
   - Verify system integrity

#### 3. Recovery

1. **Patch vulnerabilities**
   - Apply security patches
   - Update configurations
   - Deploy fixes

2. **Restore services**
   - Verify system integrity
   - Test functionality
   - Monitor for anomalies

### Regular Security Tasks

#### Weekly Security Scan

```bash
# Scan for vulnerabilities
kubectl run security-scan --image=trivy:latest --rm -it -- trivy k8s cluster

# Check pod security policies
kubectl get psp
kubectl describe psp restricted
```

#### Monthly Security Review

1. **Review access logs**
2. **Check user permissions**
3. **Update security policies**
4. **Review incident reports**

## Backup & Recovery

### Backup Strategy

#### Database Backups

- **Frequency**: Daily at 2 AM UTC
- **Retention**: 30 days
- **Location**: S3-compatible storage
- **Encryption**: AES-256

#### Configuration Backups

- **Frequency**: On every change
- **Retention**: Indefinite
- **Location**: Git repository
- **Version Control**: Git history

### Recovery Procedures

#### Full System Recovery

1. **Restore infrastructure**
   ```bash
   # Deploy Kubernetes cluster
   # Install ArgoCD
   # Configure monitoring
   ```

2. **Restore applications**
   ```bash
   # Sync ArgoCD applications
   argocd app sync backstage-kustomize
   argocd app sync backstage-dev
   ```

3. **Restore data**
   ```bash
   # Restore database from backup
   kubectl exec -i <postgres-pod> -n backstage -- psql -U backstage backstage < latest-backup.sql
   ```

#### Partial Recovery

1. **Identify affected components**
2. **Restore specific services**
3. **Verify functionality**
4. **Monitor for issues**

## Performance Tuning

### Application Performance

#### Database Optimization

```bash
# Check slow queries
kubectl exec -it <postgres-pod> -n backstage -- psql -U backstage -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Analyze table statistics
kubectl exec -it <postgres-pod> -n backstage -- psql -U backstage -c "ANALYZE;"
```

#### Application Tuning

```bash
# Check resource usage
kubectl top pods -n backstage

# Adjust resource limits
kubectl patch deployment/backstage -n backstage -p '{"spec":{"template":{"spec":{"containers":[{"name":"backstage","resources":{"requests":{"memory":"512Mi","cpu":"250m"},"limits":{"memory":"1Gi","cpu":"500m"}}}]}}}}'
```

### Infrastructure Performance

#### Node Optimization

```bash
# Check node resources
kubectl describe nodes

# Check for resource pressure
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Network Optimization

```bash
# Check network policies
kubectl get networkpolicies -n backstage

# Monitor network usage
kubectl top pods -n backstage
```

## Emergency Contacts

### On-Call Rotation

- **Primary**: Platform Team Lead
- **Secondary**: Senior Platform Engineer
- **Escalation**: Engineering Manager

### Communication Channels

- **Incident Channel**: #incidents
- **Platform Team**: #platform-team
- **Engineering**: #engineering

### External Contacts

- **Cloud Provider**: AWS Support
- **Monitoring**: Datadog Support
- **Security**: Security Team

---

*This runbook is updated regularly. Please ensure you're using the latest version.*
