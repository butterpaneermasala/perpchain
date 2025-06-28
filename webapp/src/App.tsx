import React from 'react';
import { Box, Container, Heading, Flex, Spacer, Button } from '@chakra-ui/react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { BrowserRouter as Router, Routes, Route, Link as RouterLink } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import Collateral from './pages/Collateral';
import Oracle from './pages/Oracle';
import Trading from './pages/Trading';
import Admin from './pages/Admin';

function NavBar() {
  // Fallback: simple color mode toggle (no useColorMode or useColorModeValue)
  return (
    <Flex as="nav" align="center" p={4} mb={8} boxShadow="md" bg="#f7fafc">
      <Heading size="md">PerpChain dApp</Heading>
      <Spacer />
      <RouterLink to="/">
        <Button variant="ghost" mr={2}>Dashboard</Button>
      </RouterLink>
      <RouterLink to="/collateral">
        <Button variant="ghost" mr={2}>Collateral</Button>
      </RouterLink>
      <RouterLink to="/oracle">
        <Button variant="ghost" mr={2}>Oracle</Button>
      </RouterLink>
      <RouterLink to="/trading">
        <Button variant="ghost" mr={2}>Trading</Button>
      </RouterLink>
      <RouterLink to="/admin">
        <Button variant="ghost" mr={4}>Admin</Button>
      </RouterLink>
      {/* Remove color mode toggle if hooks are not available */}
      <ConnectButton />
    </Flex>
  );
}

function App() {
  return (
    <Router>
      <Box minH="100vh" bg="#edf2f7">
        <NavBar />
        <Container maxW="container.md" py={8}>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/collateral" element={<Collateral />} />
            <Route path="/oracle" element={<Oracle />} />
            <Route path="/trading" element={<Trading />} />
            <Route path="/admin" element={<Admin />} />
          </Routes>
        </Container>
      </Box>
    </Router>
  );
}

export default App; 