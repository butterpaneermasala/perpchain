
// Utility to load contract ABIs and addresses
import { ContractInterface } from 'ethers';

export interface ContractInfo {
  name: string;
  address: string;
  abi: ContractInterface;
}

// Hardcoded mapping from contract name to ABI file name
const contractAbiFiles: Record<string, string> = {
  DataStreamOracle: 'DataStreamOracle.json',
  CrossChainVault: 'CrossChainVault.json',
  PositionManager: 'PositionManager.json',
  PerpetualTrading: 'PerpetualTrading.json',
  LiquidationEngine: 'LiquidationEngine.json',
  CrossChainReceiver: 'CrossChainReceiver.json',
  // Add more as needed
};

// Parse addresses from rn.txt
export async function loadContractAddresses(): Promise<Record<string, string>> {
  try {
    console.log('Loading contract addresses...');
    const res = await fetch('/addresses/rn.txt');
    if (!res.ok) {
      throw new Error(`Failed to fetch addresses: ${res.status}`);
    }
    const text = await res.text();
    console.log('Raw addresses text:', text);
    
    const lines = text.split('\n');
    const addresses: Record<string, string> = {};
    for (const line of lines) {
      const match = line.match(/\s*(\w+) deployed at: (0x[0-9a-fA-F]{40})/);
      if (match) {
        addresses[match[1]] = match[2];
        console.log(`Found contract: ${match[1]} at ${match[2]}`);
      }
    }
    console.log('Loaded addresses:', addresses);
    return addresses;
  } catch (error) {
    console.error('Failed to load contract addresses:', error);
    return {};
  }
}

// Load ABI JSON
export async function loadAbi(name: string): Promise<ContractInterface> {
  const file = contractAbiFiles[name];
  if (!file) throw new Error('Unknown contract ABI: ' + name);
  try {
    const res = await fetch(`/abis/${file}`);
    const json = await res.json();
    // If the ABI is wrapped in an object (e.g. { abi: [...] }), extract it
    if (Array.isArray(json)) return json as unknown as ContractInterface;
    if (json.abi && Array.isArray(json.abi)) return json.abi as unknown as ContractInterface;
    throw new Error('Invalid ABI format for ' + name);
  } catch (error) {
    console.error(`Failed to load ABI for ${name}:`, error);
    throw error;
  }
}

// Load all contract info
export async function loadAllContracts(): Promise<ContractInfo[]> {
  const addresses = await loadContractAddresses();
  const infos: ContractInfo[] = [];
  for (const name of Object.keys(addresses)) {
    try {
      const abi = await loadAbi(name);
      infos.push({ name, address: addresses[name], abi });
    } catch (e) {
      // skip if ABI not found
    }
  }
  return infos;
}
