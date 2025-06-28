import React from 'react';
import ReactDOM from 'react-dom/client';
import { ChakraProvider } from '@chakra-ui/react';
import { WagmiProvider, createConfig, http } from 'wagmi';
import { getDefaultWallets, RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { mainnet, sepolia } from 'wagmi/chains'; // Import from wagmi/chains
import App from './App';
import '@rainbow-me/rainbowkit/styles.css';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Define your custom chain
const anvilChain = {
  id: 31337,
  name: 'Anvil',
  network: 'anvil',
  nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['http://localhost:8545'] },
    public: { http: ['http://localhost:8545'] },
  },
  blockExplorers: {
    default: { name: 'Anvil', url: '' },
  },
  testnet: true,
} as const; // Use 'as const' for type inference

const chains = [anvilChain];

// RainbowKit wallet connectors
const { connectors } = getDefaultWallets({
  appName: 'PerpChain dApp',
  projectId: 'perpchain-dapp',
});

// wagmi config - Fixed createConfig usage
const config = createConfig({
  chains: chains as any, // Temporary workaround for type issue
  connectors,
  transports: {
    [anvilChain.id]: http(),
  },
});

const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <WagmiProvider config={config}>
        <ChakraProvider>
          <RainbowKitProvider>
            <App />
          </RainbowKitProvider>
        </ChakraProvider>
      </WagmiProvider>
    </QueryClientProvider>
  </React.StrictMode>
);
