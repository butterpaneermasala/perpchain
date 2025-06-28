
import React from 'react';
import { Wallet, LogOut, AlertCircle } from 'lucide-react';
import { useWeb3 } from '../contexts/Web3Context';
import { Button } from './ui/button';
import { Card } from './ui/card';

export const WalletConnection: React.FC = () => {
  const { account, connecting, connected, connect, disconnect, chainId } = useWeb3();

  if (connected && account) {
    return (
      <Card className="p-4 border-4 border-[#43d9ad] shadow-[4px_4px_0px_0px_#43d9ad] bg-[#43d9ad]">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Wallet className="h-5 w-5 text-[#232946]" />
            <div>
              <p className="font-bold text-[#232946]">
                {account.slice(0, 6)}...{account.slice(-4)}
              </p>
              <p className="text-sm text-[#232946]/70">
                Chain ID: {chainId}
              </p>
            </div>
          </div>
          <Button
            onClick={disconnect}
            variant="outline"
            size="sm"
            className="border-2 border-[#232946] hover:bg-[#232946] hover:text-white"
          >
            <LogOut className="h-4 w-4 mr-2" />
            Disconnect
          </Button>
        </div>
      </Card>
    );
  }

  return (
    <Card className="p-6 text-center border-4 border-[#232946] shadow-[8px_8px_0px_0px_#eebbc3]">
      <div className="flex flex-col items-center gap-4">
        <div className="flex items-center gap-2 text-orange-600">
          <AlertCircle className="h-5 w-5" />
          <span className="font-bold">Wallet Required</span>
        </div>
        <p className="text-[#666] text-sm">
          Connect your wallet to start trading and interact with smart contracts
        </p>
        <Button
          onClick={connect}
          disabled={connecting}
          className="bg-[#232946] hover:bg-[#43d9ad] hover:text-[#232946] text-white border-4 border-[#232946] font-bold px-6 py-3 shadow-[4px_4px_0px_0px_#43d9ad] hover:shadow-[2px_2px_0px_0px_#232946] transition-all"
        >
          <Wallet className="h-4 w-4 mr-2" />
          {connecting ? 'Connecting...' : 'Connect Wallet'}
        </Button>
      </div>
    </Card>
  );
};
