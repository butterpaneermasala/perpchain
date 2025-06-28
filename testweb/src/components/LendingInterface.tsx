import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { 
  Wallet, 
  ArrowUpDown, 
  TrendingUp, 
  Globe, 
  DollarSign, 
  AlertTriangle,
  CheckCircle,
  Clock
} from 'lucide-react';
import { useWeb3 } from '../contexts/Web3Context';
import { useContract } from '../hooks/useContract';
import { toast } from 'sonner';
import { ethers } from 'ethers';

export default function LendingInterface() {
  const { connected, account } = useWeb3();
  const { contract: lendingPoolContract, loading: lendingPoolLoading } = useContract('CrossChainLendingPool');
  const { contract: vaultContract } = useContract('CrossChainVault');

  const [activeTab, setActiveTab] = useState('deposit');
  const [selectedToken, setSelectedToken] = useState('USDC');
  const [amount, setAmount] = useState('');
  const [executing, setExecuting] = useState(false);
  const [userBalances, setUserBalances] = useState<Record<string, string>>({});
  const [poolInfo, setPoolInfo] = useState<Record<string, any>>({});
  const [selectedChain, setSelectedChain] = useState('ethereum-sepolia');

  const supportedTokens = [
    { symbol: 'USDC', address: '0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519', decimals: 18 },
    { symbol: 'ETH', address: '0x0000000000000000000000000000000000000000', decimals: 18 },
    { symbol: 'BTC', address: '0x0000000000000000000000000000000000000000', decimals: 18 }
  ];

  const supportedChains = [
    { name: 'Ethereum Sepolia', selector: '16015286601757825753', id: 'ethereum-sepolia' },
    { name: 'Avalanche Fuji', selector: '14767482510784806043', id: 'avalanche-fuji' },
    { name: 'BNB Chain Testnet', selector: '13264668187771770619', id: 'bnb-testnet' },
    { name: 'Base Sepolia', selector: '10344971235874465080', id: 'base-sepolia' }
  ];

  // Fetch user balances and pool information
  useEffect(() => {
    const fetchData = async () => {
      if (!lendingPoolContract || !account) return;

      try {
        // Fetch user deposits for each token
        const balances: Record<string, string> = {};
        for (const token of supportedTokens) {
          try {
            const deposit = await lendingPoolContract.getUserDeposit(account, token.address);
            balances[token.symbol] = ethers.formatUnits(deposit, token.decimals);
          } catch (error) {
            balances[token.symbol] = '0';
          }
        }
        setUserBalances(balances);

        // Fetch pool information
        const poolData: Record<string, any> = {};
        for (const token of supportedTokens) {
          try {
            const pool = await lendingPoolContract.pools(token.address);
            const availableLiquidity = await lendingPoolContract.getAvailableLiquidity(token.address);
            poolData[token.symbol] = {
              totalDeposits: ethers.formatUnits(pool.totalDeposits, token.decimals),
              totalBorrows: ethers.formatUnits(pool.totalBorrows, token.decimals),
              totalInterest: ethers.formatUnits(pool.totalInterest, token.decimals),
              interestRate: pool.interestRate / 100, // Convert from basis points to percentage
              availableLiquidity: ethers.formatUnits(availableLiquidity, token.decimals)
            };
          } catch (error) {
            poolData[token.symbol] = {
              totalDeposits: '0',
              totalBorrows: '0',
              totalInterest: '0',
              interestRate: 0,
              availableLiquidity: '0'
            };
          }
        }
        setPoolInfo(poolData);
      } catch (error) {
        console.error('Error fetching lending data:', error);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 10000); // Refresh every 10 seconds
    return () => clearInterval(interval);
  }, [lendingPoolContract, account]);

  const deposit = async () => {
    if (!lendingPoolContract || !amount || !selectedToken) {
      toast.error('Please enter an amount and select a token');
      return;
    }

    const token = supportedTokens.find(t => t.symbol === selectedToken);
    if (!token) return;

    try {
      setExecuting(true);
      const amountWei = ethers.parseUnits(amount, token.decimals);
      
      // First approve the lending pool to spend tokens
      // Note: This assumes the user has already approved the vault
      const tx = await lendingPoolContract.finalizeCrossChainDeposit(
        account,
        token.address,
        amountWei,
        ethers.id('local-deposit') // Mock message ID for local deposit
      );
      
      toast.info('Depositing funds... Please wait for confirmation');
      await tx.wait();
      toast.success('Deposit successful!');
      setAmount('');
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      toast.error('Failed to deposit: ' + errorMessage);
    } finally {
      setExecuting(false);
    }
  };

  const withdraw = async () => {
    if (!lendingPoolContract || !amount || !selectedToken) {
      toast.error('Please enter an amount and select a token');
      return;
    }

    const token = supportedTokens.find(t => t.symbol === selectedToken);
    if (!token) return;

    const userBalance = parseFloat(userBalances[selectedToken] || '0');
    if (parseFloat(amount) > userBalance) {
      toast.error('Insufficient balance');
      return;
    }

    try {
      setExecuting(true);
      const amountWei = ethers.parseUnits(amount, token.decimals);
      
      const tx = await lendingPoolContract.initiateCrossChainWithdrawal(
        0, // Source chain selector (0 for local)
        token.address,
        amountWei,
        { value: ethers.parseEther('0.01') } // CCIP fee
      );
      
      toast.info('Withdrawing funds... Please wait for confirmation');
      await tx.wait();
      toast.success('Withdrawal initiated!');
      setAmount('');
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      toast.error('Failed to withdraw: ' + errorMessage);
    } finally {
      setExecuting(false);
    }
  };

  const initiateCrossChainDeposit = async () => {
    if (!lendingPoolContract || !amount || !selectedToken || !selectedChain) {
      toast.error('Please fill in all fields');
      return;
    }

    const token = supportedTokens.find(t => t.symbol === selectedToken);
    const chain = supportedChains.find(c => c.id === selectedChain);
    if (!token || !chain) return;

    try {
      setExecuting(true);
      const amountWei = ethers.parseUnits(amount, token.decimals);
      const chainSelector = BigInt(chain.selector);
      
      const tx = await lendingPoolContract.initiateCrossChainDeposit(
        chainSelector,
        token.address,
        amountWei,
        { value: ethers.parseEther('0.01') } // CCIP fee
      );
      
      toast.info('Initiating cross-chain deposit... Please wait for confirmation');
      await tx.wait();
      toast.success('Cross-chain deposit initiated!');
      setAmount('');
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      toast.error('Failed to initiate cross-chain deposit: ' + errorMessage);
    } finally {
      setExecuting(false);
    }
  };

  if (!connected) {
    return (
      <div className="max-w-4xl mx-auto p-8">
        <div className="mb-8">
          <h1 className="text-4xl font-black mb-2 text-[#232946] flex items-center gap-4">
            <Wallet className="h-10 w-10 text-[#43d9ad]" />
            Lending Pool
          </h1>
          <p className="text-[#666] font-bold">Connect your wallet to access lending features</p>
        </div>
        <div className="bg-white border-4 border-[#232946] rounded-lg shadow-[8px_8px_0px_0px_#43d9ad] p-8 text-center">
          <h3 className="font-bold text-xl mb-4 text-[#232946]">Connect Your Wallet</h3>
          <p className="mb-4 text-[#666]">Please connect your wallet to deposit, withdraw, or transfer assets.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto p-8">
      <div className="mb-8">
        <h1 className="text-4xl font-black mb-2 text-[#232946] flex items-center gap-4">
          <Wallet className="h-10 w-10 text-[#43d9ad]" />
          Lending Pool
        </h1>
        <p className="text-[#666] font-bold">Deposit assets to earn interest and enable cross-chain trading</p>
      </div>

      {/* Pool Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {supportedTokens.map(token => (
          <Card key={token.symbol} className="border-4 border-[#232946] shadow-[4px_4px_0px_0px_#43d9ad]">
            <CardHeader className="pb-2">
              <CardTitle className="text-lg flex items-center justify-between">
                <span>{token.symbol}</span>
                <TrendingUp className="w-5 h-5 text-green-500" />
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Interest Rate:</span>
                <span className="font-semibold text-green-600">
                  {poolInfo[token.symbol]?.interestRate || 0}%
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Total Deposits:</span>
                <span className="font-semibold">
                  {parseFloat(poolInfo[token.symbol]?.totalDeposits || '0').toLocaleString()}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Available:</span>
                <span className="font-semibold text-blue-600">
                  {parseFloat(poolInfo[token.symbol]?.availableLiquidity || '0').toLocaleString()}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Your Balance:</span>
                <span className="font-semibold">
                  {parseFloat(userBalances[token.symbol] || '0').toFixed(2)}
                </span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Main Interface */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* Local Operations */}
        <Card className="border-4 border-[#232946] shadow-[8px_8px_0px_0px_#43d9ad]">
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Wallet className="w-5 h-5" />
              <span>Local Operations</span>
            </CardTitle>
            <CardDescription>Deposit and withdraw assets on the current chain</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Token</label>
              <Select value={selectedToken} onValueChange={setSelectedToken}>
                <SelectTrigger>
                  <SelectValue placeholder="Select token" />
                </SelectTrigger>
                <SelectContent>
                  {supportedTokens.map(token => (
                    <SelectItem key={token.symbol} value={token.symbol}>
                      {token.symbol}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Amount</label>
              <Input
                type="number"
                placeholder="0.00"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
              />
            </div>

            <div className="flex space-x-2">
              <Button 
                onClick={deposit} 
                disabled={executing || lendingPoolLoading}
                className="flex-1 bg-[#43d9ad] hover:bg-[#3b82f6] text-[#232946] border-4 border-[#232946] font-bold shadow-[4px_4px_0px_0px_#232946] hover:shadow-[2px_2px_0px_0px_#43d9ad] transition-all"
              >
                {executing ? 'Depositing...' : 'Deposit'}
              </Button>
              <Button 
                onClick={withdraw} 
                disabled={executing || lendingPoolLoading}
                variant="outline"
                className="flex-1 border-4 border-[#232946] font-bold"
              >
                {executing ? 'Withdrawing...' : 'Withdraw'}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Cross-Chain Operations */}
        <Card className="border-4 border-[#232946] shadow-[8px_8px_0px_0px_#43d9ad]">
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Globe className="w-5 h-5" />
              <span>Cross-Chain Operations</span>
            </CardTitle>
            <CardDescription>Transfer assets between different blockchains</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Destination Chain</label>
              <Select value={selectedChain} onValueChange={setSelectedChain}>
                <SelectTrigger>
                  <SelectValue placeholder="Select chain" />
                </SelectTrigger>
                <SelectContent>
                  {supportedChains.map(chain => (
                    <SelectItem key={chain.id} value={chain.id}>
                      {chain.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Token</label>
              <Select value={selectedToken} onValueChange={setSelectedToken}>
                <SelectTrigger>
                  <SelectValue placeholder="Select token" />
                </SelectTrigger>
                <SelectContent>
                  {supportedTokens.map(token => (
                    <SelectItem key={token.symbol} value={token.symbol}>
                      {token.symbol}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Amount</label>
              <Input
                type="number"
                placeholder="0.00"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
              />
            </div>

            <Button 
              onClick={initiateCrossChainDeposit} 
              disabled={executing || lendingPoolLoading}
              className="w-full bg-[#3b82f6] hover:bg-[#43d9ad] text-white border-4 border-[#232946] font-bold shadow-[4px_4px_0px_0px_#232946] hover:shadow-[2px_2px_0px_0px_#43d9ad] transition-all"
            >
              {executing ? 'Initiating Transfer...' : 'Transfer Cross-Chain'}
            </Button>

            <div className="flex items-center space-x-2 text-sm text-gray-600 bg-blue-50 p-3 rounded-lg">
              <AlertTriangle className="w-4 h-4 text-blue-500" />
              <span>Cross-chain transfers may take 5-10 minutes to complete</span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <Card className="border-4 border-[#232946] shadow-[4px_4px_0px_0px_#43d9ad]">
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Clock className="w-5 h-5" />
            <span>Recent Activity</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-gray-500">
            <p>No recent activity</p>
            <p className="text-sm">Your lending transactions will appear here</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
} 