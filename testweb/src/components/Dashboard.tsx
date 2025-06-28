
import React from 'react';
import { useWallet } from '../utils/useWallet';

interface DashboardProps {
  contracts: string[];
  addresses: Record<string, string>;
}

export default function Dashboard({ contracts, addresses }: DashboardProps) {
  const { address: userAddress, connect } = useWallet();

  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-4xl font-black mb-2 text-[#232946]">PerpChain Dashboard</h1>
      <div className="text-[#666] mb-8">
        Decentralized perpetual trading platform
      </div>

      <div className="bg-gradient-to-r from-[#43d9ad] to-[#3b82f6] text-white border-4 border-[#232946] rounded-lg shadow-[8px_8px_0px_0px_#232946] p-8 mb-8">
        <h2 className="text-2xl font-black mb-4">Welcome to PerpChain</h2>
        <p className="font-bold leading-relaxed">
          PerpChain is a cross-chain perpetual trading platform that allows you to trade with leverage across multiple blockchain networks. 
          Connect your wallet to start interacting with the smart contracts.
        </p>
      </div>

      <div className="mb-8">
        {userAddress && typeof userAddress === 'string' ? (
          <div className="bg-[#43d9ad] text-[#232946] border-4 border-[#232946] rounded-lg shadow-[4px_4px_0px_0px_#232946] p-6">
            <span className="font-bold text-lg">
              ✅ Connected: {userAddress.slice(0, 6)}...{userAddress.slice(-4)}
            </span>
          </div>
        ) : (
          <div className="bg-white border-4 border-[#232946] rounded-lg shadow-[8px_8px_0px_0px_#232946] p-8 text-center">
            <h3 className="font-bold text-xl mb-4 text-[#232946]">Connect Your Wallet</h3>
            <button 
              onClick={connect} 
              className="bg-[#232946] hover:bg-[#43d9ad] hover:text-[#232946] text-white border-4 border-[#232946] font-bold text-lg px-8 py-4 rounded-lg shadow-[4px_4px_0px_0px_#43d9ad] hover:shadow-[2px_2px_0px_0px_#232946] transition-all"
            >
              Connect Wallet
            </button>
          </div>
        )}
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {contracts.map(contract => (
          <div key={contract} className="bg-white border-4 border-[#232946] rounded-lg shadow-[8px_8px_0px_0px_#232946] p-6">
            <div className="font-black text-xl mb-2 text-[#232946]">{contract}</div>
            <div className="text-xs text-[#666] mb-4 font-mono break-all">
              {addresses[contract] || 'Loading...'}
            </div>
            <div className="text-sm mb-4 leading-relaxed text-[#666]">
              {getContractDescription(contract)}
            </div>
            {addresses[contract] && (
              <div className="inline-block bg-[#43d9ad] text-[#232946] border-2 border-[#232946] rounded-lg px-3 py-1 text-sm font-bold">
                ✅ Deployed
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

function getContractDescription(contract: string): string {
  const descriptions: Record<string, string> = {
    DataStreamOracle: 'Provides real-time price feeds for trading pairs using Chainlink data streams.',
    CrossChainVault: 'Manages cross-chain asset deposits and withdrawals with secure bridging.',
    PositionManager: 'Handles opening, closing, and managing perpetual trading positions.',
    PerpetualTrading: 'Core trading engine for leveraged perpetual contracts.',
    LiquidationEngine: 'Monitors and executes liquidations of undercollateralized positions.',
    CrossChainReceiver: 'Receives and processes cross-chain messages and transactions.'
  };
  return descriptions[contract] || 'Smart contract component of the PerpChain platform.';
}
