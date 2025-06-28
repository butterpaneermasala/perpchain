import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { TrendingUp, TrendingDown, DollarSign, BarChart3, Zap, AlertTriangle } from 'lucide-react';
import { useWeb3 } from '../contexts/Web3Context';
import { useContract } from '../hooks/useContract';
import { WalletConnection } from './WalletConnection';
import { toast } from 'sonner';
import { ethers } from 'ethers';

export default function TradingInterface() {
  const { connected } = useWeb3();
  const { contract: perpetualContract, loading: perpetualLoading } = useContract('PerpetualTrading');
  const { contract: positionContract, loading: positionLoading } = useContract('PositionManager');
  const { contract: oracleContract } = useContract('DataStreamOracle');

  const [selectedPair, setSelectedPair] = useState('ETH/USD');
  const [position, setPosition] = useState<'long' | 'short'>('long');
  const [leverage, setLeverage] = useState('10');
  const [amount, setAmount] = useState('');
  const [collateralAmount, setCollateralAmount] = useState('');
  const [executing, setExecuting] = useState(false);
  const [prices, setPrices] = useState<Record<string, number>>({});

  const tradingPairs = [
    { pair: 'ETH/USD', price: '$2,435.67', change: '+2.34%', isUp: true, bytes32: ethers.id('ETH/USD') },
    { pair: 'BTC/USD', price: '$45,123.89', change: '-1.23%', isUp: false, bytes32: ethers.id('BTC/USD') },
    { pair: 'AVAX/USD', price: '$31.45', change: '+5.67%', isUp: true, bytes32: ethers.id('AVAX/USD') },
    { pair: 'MATIC/USD', price: '$0.85', change: '+3.21%', isUp: true, bytes32: ethers.id('MATIC/USD') },
  ];

  const leverageOptions = ['5', '10', '20', '50', '100'];

  // Fetch current prices from oracle
  useEffect(() => {
    const fetchPrices = async () => {
      if (!oracleContract) return;
      
      try {
        const latestPrice = await oracleContract.getLatestPrice();
        console.log('Latest price from oracle:', latestPrice.toString());
        // You can expand this to fetch prices for all pairs
      } catch (error) {
        console.error('Error fetching prices:', error);
      }
    };

    fetchPrices();
  }, [oracleContract]);

  const depositCollateral = async () => {
    if (!perpetualContract || !collateralAmount) {
      toast.error('Please enter collateral amount');
      return;
    }

    try {
      setExecuting(true);
      const collateralTokenAddress = '0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519'; // Mock ERC20 from deployment
      const amountWei = ethers.parseUnits(collateralAmount, 18);
      
      const tx = await perpetualContract.depositCollateral(collateralTokenAddress, amountWei);
      toast.info('Depositing collateral... Please wait for confirmation');
      
      await tx.wait();
      toast.success('Collateral deposited successfully!');
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      toast.error('Failed to deposit collateral: ' + errorMessage);
    } finally {
      setExecuting(false);
    }
  };

  const openPosition = async () => {
    if (!positionContract || !amount) {
      toast.error('Please enter position size');
      return;
    }

    try {
      setExecuting(true);
      const selectedPairData = tradingPairs.find(p => p.pair === selectedPair);
      if (!selectedPairData) {
        toast.error('Invalid trading pair');
        return;
      }

      const positionType = position === 'long' ? 0 : 1; // 0 for long, 1 for short
      const sizeWei = ethers.parseUnits(amount, 18);
      const leverageAmount = parseInt(leverage);

      const tx = await positionContract.openPosition(
        selectedPairData.bytes32,
        positionType,
        sizeWei,
        leverageAmount
      );
      
      toast.info('Opening position... Please wait for confirmation');
      await tx.wait();
      toast.success(`${position.toUpperCase()} position opened successfully!`);
      
      // Clear form
      setAmount('');
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      toast.error('Failed to open position: ' + errorMessage);
    } finally {
      setExecuting(false);
    }
  };

  if (!connected) {
    return (
      <div className="max-w-6xl mx-auto p-8">
        <div className="mb-8">
          <h1 className="text-4xl font-black mb-2 text-[#232946] flex items-center gap-4">
            <BarChart3 className="h-10 w-10 text-[#43d9ad]" />
            Perpetual Trading
          </h1>
          <p className="text-[#666] font-bold">Connect your wallet to start trading</p>
        </div>
        <WalletConnection />
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto p-8">
      <div className="mb-8">
        <h1 className="text-4xl font-black mb-2 text-[#232946] flex items-center gap-4">
          <BarChart3 className="h-10 w-10 text-[#43d9ad]" />
          Perpetual Trading
        </h1>
        <p className="text-[#666] font-bold">Trade with leverage across multiple chains</p>
      </div>

      <div className="mb-6">
        <WalletConnection />
      </div>

      {/* Contract Status */}
      <div className="mb-6">
        <Card className="border-4 border-[#232946] shadow-[4px_4px_0px_0px_#eebbc3]">
          <CardHeader className="bg-[#f0f0f0] border-b-4 border-[#232946]">
            <CardTitle className="text-lg font-black">Smart Contract Status</CardTitle>
          </CardHeader>
          <CardContent className="p-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="flex items-center gap-2">
                <div className={`w-3 h-3 rounded-full ${perpetualLoading ? 'bg-yellow-500' : perpetualContract ? 'bg-green-500' : 'bg-red-500'}`} />
                <span className="font-bold">Perpetual Trading</span>
              </div>
              <div className="flex items-center gap-2">
                <div className={`w-3 h-3 rounded-full ${positionLoading ? 'bg-yellow-500' : positionContract ? 'bg-green-500' : 'bg-red-500'}`} />
                <span className="font-bold">Position Manager</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-8 lg:grid-cols-3">
        {/* Trading Pairs */}
        <Card className="lg:col-span-2 border-4 border-[#232946] shadow-[8px_8px_0px_0px_#232946]">
          <CardHeader className="bg-gradient-to-r from-[#43d9ad] to-[#3b82f6] text-white border-b-4 border-[#232946]">
            <CardTitle className="text-2xl font-black">Market Overview</CardTitle>
            <CardDescription className="text-white/90 font-bold">
              Real-time prices and 24h changes
            </CardDescription>
          </CardHeader>
          <CardContent className="p-6">
            <div className="space-y-4">
              {tradingPairs.map((pair) => (
                <div
                  key={pair.pair}
                  className={`p-4 rounded-lg border-4 cursor-pointer transition-all ${
                    selectedPair === pair.pair
                      ? 'bg-[#43d9ad] border-[#43d9ad] text-[#232946] shadow-[4px_4px_0px_0px_#232946]'
                      : 'bg-white border-[#232946] hover:bg-[#f0f0f0]'
                  }`}
                  onClick={() => setSelectedPair(pair.pair)}
                >
                  <div className="flex justify-between items-center">
                    <div>
                      <h3 className="font-black text-lg">{pair.pair}</h3>
                      <p className="font-bold text-2xl">{pair.price}</p>
                    </div>
                    <div className={`flex items-center gap-2 font-bold ${
                      pair.isUp ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {pair.isUp ? <TrendingUp className="h-5 w-5" /> : <TrendingDown className="h-5 w-5" />}
                      {pair.change}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Trading Panel */}
        <div className="space-y-6">
          {/* Collateral Deposit */}
          <Card className="border-4 border-[#232946] shadow-[8px_8px_0px_0px_#232946]">
            <CardHeader className="bg-[#eebbc3] text-[#232946] border-b-4 border-[#232946]">
              <CardTitle className="text-lg font-black flex items-center gap-2">
                <Zap className="h-5 w-5" />
                Deposit Collateral
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4 space-y-4">
              <div className="space-y-2">
                <label className="text-sm font-bold text-[#232946]">Amount (USDC)</label>
                <Input
                  type="number"
                  placeholder="100.00"
                  value={collateralAmount}
                  onChange={(e) => setCollateralAmount(e.target.value)}
                  className="border-4 border-[#232946] font-bold"
                />
              </div>
              <Button
                onClick={depositCollateral}
                disabled={executing || !collateralAmount}
                className="w-full bg-[#eebbc3] hover:bg-[#e0a8b3] text-[#232946] border-4 border-[#232946] font-bold shadow-[4px_4px_0px_0px_#232946] hover:shadow-[2px_2px_0px_0px_#232946] transition-all"
              >
                {executing ? 'Depositing...' : 'Deposit Collateral'}
              </Button>
            </CardContent>
          </Card>

          {/* Position Opening */}
          <Card className="border-4 border-[#232946] shadow-[8px_8px_0px_0px_#232946]">
            <CardHeader className="bg-[#232946] text-white border-b-4 border-[#232946]">
              <CardTitle className="text-xl font-black flex items-center gap-2">
                <DollarSign className="h-6 w-6" />
                Open Position
              </CardTitle>
              <CardDescription className="text-white/90 font-bold">
                {selectedPair}
              </CardDescription>
            </CardHeader>
            <CardContent className="p-6 space-y-6">
              {/* Position Type */}
              <div className="space-y-2">
                <label className="text-sm font-bold text-[#232946]">Position Type</label>
                <div className="grid grid-cols-2 gap-2">
                  <Button
                    variant={position === 'long' ? 'default' : 'outline'}
                    onClick={() => setPosition('long')}
                    className={`font-bold border-4 border-[#232946] ${
                      position === 'long'
                        ? 'bg-green-500 hover:bg-green-600 text-white'
                        : 'bg-white hover:bg-green-50 text-[#232946]'
                    } shadow-[2px_2px_0px_0px_#232946]`}
                  >
                    Long
                  </Button>
                  <Button
                    variant={position === 'short' ? 'default' : 'outline'}
                    onClick={() => setPosition('short')}
                    className={`font-bold border-4 border-[#232946] ${
                      position === 'short'
                        ? 'bg-red-500 hover:bg-red-600 text-white'
                        : 'bg-white hover:bg-red-50 text-[#232946]'
                    } shadow-[2px_2px_0px_0px_#232946]`}
                  >
                    Short
                  </Button>
                </div>
              </div>

              {/* Leverage */}
              <div className="space-y-2">
                <label className="text-sm font-bold text-[#232946]">Leverage</label>
                <Select value={leverage} onValueChange={setLeverage}>
                  <SelectTrigger className="border-4 border-[#232946] font-bold">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {leverageOptions.map((lev) => (
                      <SelectItem key={lev} value={lev}>
                        {lev}x
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Amount */}
              <div className="space-y-2">
                <label className="text-sm font-bold text-[#232946]">Position Size (USDC)</label>
                <Input
                  type="number"
                  placeholder="0.00"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="border-4 border-[#232946] font-bold"
                />
              </div>

              {/* Open Position Button */}
              <Button
                onClick={openPosition}
                disabled={executing || !amount || !positionContract}
                className={`w-full font-bold text-lg py-6 border-4 border-[#232946] shadow-[4px_4px_0px_0px_#232946] hover:shadow-[2px_2px_0px_0px_#232946] transition-all ${
                  position === 'long'
                    ? 'bg-green-500 hover:bg-green-600 text-white'
                    : 'bg-red-500 hover:bg-red-600 text-white'
                }`}
              >
                {executing ? 'Processing...' : `Open ${position.toUpperCase()} Position`}
              </Button>

              {/* Risk Warning */}
              <div className="bg-orange-100 border-4 border-orange-500 p-4 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="h-5 w-5 text-orange-600" />
                  <span className="font-bold text-orange-800">Risk Warning</span>
                </div>
                <p className="text-sm font-bold text-orange-800">
                  Trading with leverage involves substantial risk. Never risk more than you can afford to lose.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
