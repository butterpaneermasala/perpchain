import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { ethers } from 'ethers';
import { toast } from 'sonner';

interface Web3ContextType {
  provider: ethers.BrowserProvider | null;
  signer: ethers.Signer | null;
  account: string | null;
  chainId: number | null;
  connecting: boolean;
  connected: boolean;
  connect: () => Promise<void>;
  disconnect: () => void;
  switchNetwork: (chainId: number) => Promise<void>;
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined);

export const useWeb3 = () => {
  const context = useContext(Web3Context);
  if (!context) {
    throw new Error('useWeb3 must be used within a Web3Provider');
  }
  return context;
};

interface Web3ProviderProps {
  children: ReactNode;
}

export const Web3Provider: React.FC<Web3ProviderProps> = ({ children }) => {
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const [account, setAccount] = useState<string | null>(null);
  const [chainId, setChainId] = useState<number | null>(null);
  const [connecting, setConnecting] = useState(false);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    // Check if already connected
    if (typeof window !== 'undefined' && window.ethereum) {
      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      setProvider(browserProvider);
      
      // Check if already connected
      browserProvider.send('eth_accounts', []).then((accounts: string[]) => {
        if (accounts.length > 0) {
          setAccount(accounts[0]);
          setConnected(true);
          browserProvider.getSigner().then(setSigner);
          browserProvider.getNetwork().then(network => setChainId(Number(network.chainId)));
        }
      });

      // Listen for account changes
      window.ethereum.on('accountsChanged', (accounts: string[]) => {
        if (accounts.length === 0) {
          disconnect();
        } else {
          setAccount(accounts[0]);
          if (provider) {
            provider.getSigner().then(setSigner);
          }
        }
      });

      // Listen for chain changes
      window.ethereum.on('chainChanged', (chainId: string) => {
        setChainId(parseInt(chainId, 16));
      });
    }
  }, []);

  const connect = async () => {
    if (!provider) {
      toast.error('Please install MetaMask or another Web3 wallet');
      return;
    }

    try {
      setConnecting(true);
      const accounts = await provider.send('eth_requestAccounts', []);
      
      if (accounts.length > 0) {
        setAccount(accounts[0]);
        setConnected(true);
        const signer = await provider.getSigner();
        setSigner(signer);
        const network = await provider.getNetwork();
        setChainId(Number(network.chainId));
        toast.success('Wallet connected successfully!');
      }
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      toast.error('Failed to connect wallet: ' + errorMessage);
    } finally {
      setConnecting(false);
    }
  };

  const disconnect = () => {
    setAccount(null);
    setSigner(null);
    setConnected(false);
    setChainId(null);
    toast.info('Wallet disconnected');
  };

  const switchNetwork = async (targetChainId: number) => {
    if (!provider) return;

    try {
      await provider.send('wallet_switchEthereumChain', [
        { chainId: `0x${targetChainId.toString(16)}` }
      ]);
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      toast.error('Failed to switch network: ' + errorMessage);
    }
  };

  return (
    <Web3Context.Provider value={{
      provider,
      signer,
      account,
      chainId,
      connecting,
      connected,
      connect,
      disconnect,
      switchNetwork
    }}>
      {children}
    </Web3Context.Provider>
  );
};
