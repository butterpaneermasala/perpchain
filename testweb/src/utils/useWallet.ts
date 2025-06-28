import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

declare global {
  interface Window {
    ethereum?: {
      request: (args: { method: string; params?: unknown[] }) => Promise<unknown>;
      on: (event: string, callback: (...args: unknown[]) => void) => void;
      removeListener: (event: string, callback: (...args: unknown[]) => void) => void;
    };
  }
}

export function useWallet() {
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const [address, setAddress] = useState<string | null>(null);

  useEffect(() => {
    if (window.ethereum) {
      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      setProvider(browserProvider);
      browserProvider.send('eth_accounts', []).then((accounts: string[]) => {
        if (accounts.length > 0) {
          setAddress(accounts[0]);
          browserProvider.getSigner().then(setSigner);
        }
      });
    }
  }, []);

  const connect = async () => {
    if (!provider) return;
    const accounts = await provider.send('eth_requestAccounts', []);
    setAddress(accounts[0]);
    setSigner(await provider.getSigner());
  };

  return { provider, signer, address, connect };
}
