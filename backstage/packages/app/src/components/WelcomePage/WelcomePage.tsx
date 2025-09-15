import React from 'react';
import {
  Page,
  Header,
  Content,
  HeaderLabel,
  InfoCard,
  MarkdownContent,
} from '@backstage/core-components';
import { Grid, Typography, Box } from '@material-ui/core';

export const WelcomePage = () => {
  const welcomeContent = `
# Welcome to ULP Backstage! 🚀

Welcome to the **Ultimate Learning Platform (ULP) Backstage Developer Portal**!

This is your central hub for discovering, managing, and building software components and services.

## What you can do here:

- **📚 Browse the Catalog** - Discover all your services, APIs, and components
- **🔍 Search** - Find anything across your organization
- **📖 Documentation** - Access technical documentation and guides
- **🛠️ Create** - Build new components using our templates
- **📊 Monitor** - Track the health and status of your services

## Getting Started

1. **Explore the Catalog** - Start by browsing the catalog to see what's available
2. **Check out Documentation** - Visit the docs section for detailed guides
3. **Create Something New** - Use the scaffolder to create new components

---

*Happy coding! 🎉*
  `;

  return (
    <Page themeId="home">
      <Header title="Welcome" subtitle="ULP Backstage Developer Portal">
        <HeaderLabel label="Version" value="1.0.0" />
        <HeaderLabel label="Environment" value="Development" />
      </Header>
      <Content>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <InfoCard title="Welcome Message">
              <Box padding={2}>
                <MarkdownContent content={welcomeContent} />
              </Box>
            </InfoCard>
          </Grid>
          <Grid item xs={12} md={6}>
            <InfoCard title="Quick Links">
              <Box padding={2}>
                <Typography variant="body1" paragraph>
                  <strong>📚 Catalog:</strong> Browse all your services and components
                </Typography>
                <Typography variant="body1" paragraph>
                  <strong>🔍 Search:</strong> Find anything across your organization
                </Typography>
                <Typography variant="body1" paragraph>
                  <strong>📖 Docs:</strong> Access technical documentation
                </Typography>
                <Typography variant="body1" paragraph>
                  <strong>🛠️ Create:</strong> Build new components with templates
                </Typography>
              </Box>
            </InfoCard>
          </Grid>
          <Grid item xs={12} md={6}>
            <InfoCard title="System Status">
              <Box padding={2}>
                <Typography variant="body1" paragraph>
                  ✅ <strong>Backstage:</strong> Running
                </Typography>
                <Typography variant="body1" paragraph>
                  ✅ <strong>Database:</strong> Connected
                </Typography>
                <Typography variant="body1" paragraph>
                  ✅ <strong>Search:</strong> Indexed
                </Typography>
                <Typography variant="body1" paragraph>
                  ✅ <strong>Catalog:</strong> Loaded
                </Typography>
              </Box>
            </InfoCard>
          </Grid>
        </Grid>
      </Content>
    </Page>
  );
};
