import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { 
  BookOpen, 
  Wallet, 
  DollarSign, 
  BarChart3, 
  Shield, 
  ChevronRight,
  Zap,
  AlertTriangle,
  TrendingUp,
  Code
} from 'lucide-react';

const GuideCard = ({ title, description, icon: Icon, children }: {
  title: string;
  description: string;
  icon: React.ComponentType<{ className?: string }>;
  children: React.ReactNode;
}) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <Card className="border-4 border-[#232946] shadow-[8px_8px_0px_0px_#232946] mb-6">
      <CardHeader 
        className="bg-gradient-to-r from-[#43d9ad] to-[#3b82f6] text-white border-b-4 border-[#232946] cursor-pointer"
        onClick={() => setIsOpen(!isOpen)}
      >
        <CardTitle className="text-xl font-black flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Icon className="h-6 w-6" />
            {title}
          </div>
          <ChevronRight className={`h-5 w-5 transition-transform ${isOpen ? 'rotate-90' : ''}`} />
        </CardTitle>
        <p className="text-white/90 font-bold">{description}</p>
      </CardHeader>
      {isOpen && (
        <CardContent className="p-6">
          {children}
        </CardContent>
      )}
    </Card>
  );
};

export const UserGuide: React.FC = () => {
  return (
    <div className="max-w-4xl mx-auto p-8">
      <div className="mb-8">
        <h1 className="text-4xl font-black mb-2 text-[#232946] flex items-center gap-4">
          <BookOpen className="h-10 w-10 text-[#43d9ad]" />
          User Guide & Tutorials
        </h1>
        <p className="text-[#666] font-bold">Learn how to use PerpChain's perpetual trading platform</p>
      </div>

      <GuideCard
        title="Getting Started"
        description="Setup your wallet and understand the platform"
        icon={Wallet}
      >
        <div className="space-y-4">
          <div className="bg-[#f0f0f0] border-4 border-[#232946] p-4 rounded-lg">
            <h3 className="font-black text-lg mb-2 text-[#232946]">Step 1: Install MetaMask</h3>
            <p className="text-[#666] mb-3">
              Download and install MetaMask browser extension from metamask.io
            </p>
            <ul className="list-disc list-inside text-[#666] space-y-1">
              <li>Create a new wallet or import existing one</li>
              <li>Secure your seed phrase</li>
              <li>Add test networks if needed</li>
            </ul>
          </div>

          <div className="bg-[#f0f0f0] border-4 border-[#232946] p-4 rounded-lg">
            <h3 className="font-black text-lg mb-2 text-[#232946]">Step 2: Connect to PerpChain</h3>
            <p className="text-[#666] mb-3">
              Click "Connect Wallet" on any page to link your MetaMask
            </p>
            <ul className="list-disc list-inside text-[#666] space-y-1">
              <li>Approve the connection request</li>
              <li>Verify your wallet address is displayed</li>
              <li>Check the network ID matches</li>
            </ul>
          </div>
        </div>
      </GuideCard>

      <GuideCard
        title="Smart Contracts Overview"
        description="Understand how our contracts work together"
        icon={Code}
      >
        <div className="space-y-4">
          <div className="grid md:grid-cols-2 gap-4">
            <div className="bg-blue-50 border-4 border-blue-500 p-4 rounded-lg">
              <h3 className="font-black text-lg mb-2 text-blue-800">PerpetualTrading</h3>
              <p className="text-blue-700 text-sm">
                Core contract for opening positions, managing collateral, and executing trades
              </p>
            </div>
            
            <div className="bg-green-50 border-4 border-green-500 p-4 rounded-lg">
              <h3 className="font-black text-lg mb-2 text-green-800">PositionManager</h3>
              <p className="text-green-700 text-sm">
                Handles position lifecycle, tracks user positions, and manages closures
              </p>
            </div>
            
            <div className="bg-purple-50 border-4 border-purple-500 p-4 rounded-lg">
              <h3 className="font-black text-lg mb-2 text-purple-800">DataStreamOracle</h3>
              <p className="text-purple-700 text-sm">
                Provides real-time price feeds for accurate position valuation
              </p>
            </div>
            
            <div className="bg-orange-50 border-4 border-orange-500 p-4 rounded-lg">
              <h3 className="font-black text-lg mb-2 text-orange-800">LiquidationEngine</h3>
              <p className="text-orange-700 text-sm">
                Monitors positions and executes liquidations when needed
              </p>
            </div>
          </div>
        </div>
      </GuideCard>

      <GuideCard
        title="Depositing Collateral"
        description="Fund your account to start trading"
        icon={DollarSign}
      >
        <div className="space-y-4">
          <div className="bg-[#eebbc3] border-4 border-[#232946] p-4 rounded-lg">
            <h3 className="font-black text-lg mb-2 text-[#232946]">Why Deposit Collateral?</h3>
            <p className="text-[#666] mb-3">
              Collateral secures your leveraged positions and covers potential losses
            </p>
          </div>

          <div className="space-y-3">
            <div className="flex items-start gap-3">
              <div className="bg-[#43d9ad] text-[#232946] rounded-full w-6 h-6 flex items-center justify-center font-bold text-sm">1</div>
              <div>
                <h4 className="font-bold text-[#232946]">Enter Amount</h4>
                <p className="text-[#666] text-sm">Input the USDC amount you want to deposit</p>
              </div>
            </div>
            
            <div className="flex items-start gap-3">
              <div className="bg-[#43d9ad] text-[#232946] rounded-full w-6 h-6 flex items-center justify-center font-bold text-sm">2</div>
              <div>
                <h4 className="font-bold text-[#232946]">Approve Transaction</h4>
                <p className="text-[#666] text-sm">Confirm the transaction in your wallet</p>
              </div>
            </div>
            
            <div className="flex items-start gap-3">
              <div className="bg-[#43d9ad] text-[#232946] rounded-full w-6 h-6 flex items-center justify-center font-bold text-sm">3</div>
              <div>
                <h4 className="font-bold text-[#232946]">Wait for Confirmation</h4>
                <p className="text-[#666] text-sm">Transaction will be confirmed on the blockchain</p>
              </div>
            </div>
          </div>
        </div>
      </GuideCard>

      <GuideCard
        title="Opening Positions"
        description="Start trading with leverage"
        icon={TrendingUp}
      >
        <div className="space-y-4">
          <div className="grid md:grid-cols-2 gap-4">
            <div className="bg-green-50 border-4 border-green-500 p-4 rounded-lg">
              <h3 className="font-black text-lg mb-2 text-green-800">Long Position</h3>
              <p className="text-green-700 text-sm">
                Bet that the price will go UP. You profit when the asset price increases.
              </p>
            </div>
            
            <div className="bg-red-50 border-4 border-red-500 p-4 rounded-lg">
              <h3 className="font-black text-lg mb-2 text-red-800">Short Position</h3>
              <p className="text-red-700 text-sm">
                Bet that the price will go DOWN. You profit when the asset price decreases.
              </p>
            </div>
          </div>

          <div className="bg-[#f0f0f0] border-4 border-[#232946] p-4 rounded-lg">
            <h3 className="font-black text-lg mb-2 text-[#232946]">Trading Process</h3>
            <ol className="list-decimal list-inside text-[#666] space-y-2">
              <li>Select a trading pair (ETH/USD, BTC/USD, etc.)</li>
              <li>Choose Long or Short position</li>
              <li>Set your leverage (5x to 100x)</li>
              <li>Enter position size in USDC</li>
              <li>Click "Open Position" and confirm transaction</li>
            </ol>
          </div>
        </div>
      </GuideCard>

      <GuideCard
        title="Risk Management"
        description="Understand and manage trading risks"
        icon={AlertTriangle}
      >
        <div className="space-y-4">
          <div className="bg-red-50 border-4 border-red-500 p-4 rounded-lg">
            <h3 className="font-black text-lg mb-2 text-red-800">Liquidation Risk</h3>
            <p className="text-red-700 text-sm mb-2">
              If your position loses too much value, it may be liquidated to protect the protocol.
            </p>
            <ul className="list-disc list-inside text-red-700 text-sm space-y-1">
              <li>Higher leverage = higher liquidation risk</li>
              <li>Monitor your positions regularly</li>
              <li>Consider stop-losses for protection</li>
            </ul>
          </div>

          <div className="bg-yellow-50 border-4 border-yellow-500 p-4 rounded-lg">
            <h3 className="font-black text-lg mb-2 text-yellow-800">Best Practices</h3>
            <ul className="list-disc list-inside text-yellow-700 text-sm space-y-1">
              <li>Start with lower leverage (5x-10x)</li>
              <li>Never risk more than you can afford to lose</li>
              <li>Diversify across different assets</li>
              <li>Keep some collateral in reserve</li>
            </ul>
          </div>
        </div>
      </GuideCard>

      <GuideCard
        title="Contract Interaction"
        description="Directly interact with smart contracts"
        icon={Zap}
      >
        <div className="space-y-4">
          <div className="bg-[#f0f0f0] border-4 border-[#232946] p-4 rounded-lg">
            <h3 className="font-black text-lg mb-2 text-[#232946]">Advanced Features</h3>
            <p className="text-[#666] mb-3">
              Use the contract pages to directly call smart contract functions
            </p>
            <ul className="list-disc list-inside text-[#666] space-y-1">
              <li>View contract addresses and ABIs</li>
              <li>Call read functions to get data</li>
              <li>Execute write functions to modify state</li>
              <li>Monitor transaction status</li>
            </ul>
          </div>

          <div className="bg-blue-50 border-4 border-blue-500 p-4 rounded-lg">
            <h3 className="font-black text-lg mb-2 text-blue-800">Function Types</h3>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <div className="bg-blue-500 text-white px-2 py-1 rounded text-xs font-bold">READ</div>
                <span className="text-blue-700 text-sm">View data without gas fees</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="bg-orange-500 text-white px-2 py-1 rounded text-xs font-bold">WRITE</div>
                <span className="text-orange-700 text-sm">Modify state, requires gas fees</span>
              </div>
            </div>
          </div>
        </div>
      </GuideCard>
    </div>
  );
};
