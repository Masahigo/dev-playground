import React from 'react';
import Container from '@material-ui/core/Container';
import Typography from '@material-ui/core/Typography';
import Box from '@material-ui/core/Box';
import Link from '@material-ui/core/Link';
import Logo from './Logo';
import Demo from './components/Demo';

function Copyright() {
  return (
    <Typography variant="body2" color="textSecondary" align="center">
      {'Copyright © '}
      <Link color="inherit" href="https://msdevopsdude.com/">
        MS DevOps Dude
      </Link>{' '}
      {new Date().getFullYear()}
      {'.'}
    </Typography>
  );
}

export default function App() {
  return (
    <Container maxWidth="sm">
      <Logo />
      <Box className="demo-content" my={4}>
        <Typography variant="h4" component="h1" align="center" gutterBottom>
          DEMO
        </Typography>
        <Box align="center">
          <Demo />
        </Box>
        <Copyright />
      </Box>
    </Container>
  );
}
