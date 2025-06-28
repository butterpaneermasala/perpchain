import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useWeb3 } from '../contexts/Web3Context';
import { loadAbi, loadContractAddresses } from '../utils/contracts';
import { toast } from 'sonner';

export const useContract = (contractName: string) => {
  const { signer, connected } = useWeb3();
  const [contract, setContract] = useState<ethers.Contract | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadContract = async () => {
      if (!connected || !signer) {
        setContract(null);
        setLoading(false);
        return;
      }

      try {
        setLoading(true);
        setError(null);
        
        const addresses = await loadContractAddresses();
        const abi = await loadAbi(contractName);
        
        if (!addresses[contractName]) {
          throw new Error(`Contract ${contractName} not found`);
        }

        const contractInstance = new ethers.Contract(
          addresses[contractName],
          abi,
          signer
        );

        setContract(contractInstance);
        console.log(`Contract ${contractName} loaded:`, addresses[contractName]);
      } catch (err: unknown) {
        const errorMessage = err instanceof Error ? err.message : String(err);
        setError(errorMessage);
        toast.error(`Failed to load ${contractName}: ${errorMessage}`);
      } finally {
        setLoading(false);
      }
    };

    loadContract();
  }, [contractName, signer, connected]);

  return { contract, loading, error };
};
