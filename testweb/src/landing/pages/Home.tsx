import { motion } from "framer-motion";
import { useNavigate } from "react-router-dom";
import { 
  Link2, 
  Workflow, 
  Globe, 
  Shield, 
  BarChart3, 
  File,
  Database,
  Dices,
  ArrowRightLeft,
  Settings,
  ChevronDown,
  Wallet,
  TrendingUp,
  Zap,
  Lock,
  Network
} from "lucide-react";

export default function Home() {
  const navigate = useNavigate();

  const handleLaunchApp = () => {
    // Navigate to the main app using React Router
    navigate('/app');
  };

  const handleViewDemo = () => {
    alert("Demo functionality coming soon!");
  };

  const handleConnectWallet = () => {
    alert("Wallet connection functionality coming soon!");
  };

  return (
    <div className="min-h-screen bg-black text-white overflow-x-hidden">
      {/* Dynamic Animated Background */}
      <div className="dynamic-bg">
        {/* Base gradient */}
        <div className="absolute inset-0 bg-gradient-to-br from-black via-gray-950/40 to-black"></div>
        
        {/* Moving grid lines */}
        <div className="grid-lines"></div>
        
        {/* Large moving orbs */}
        <div className="bg-orb bg-orb-1"></div>
        <div className="bg-orb bg-orb-2"></div>
        <div className="bg-orb bg-orb-3"></div>
        <div className="bg-orb bg-orb-4"></div>
        
        {/* Small floating particles */}
        <div className="absolute inset-0">
          {Array.from({ length: 12 }, (_, i) => (
            <div key={i} className="particle"></div>
          ))}
        </div>

        {/* Pulse rings */}
        <div className="pulse-ring pulse-ring-1"></div>
        <div className="pulse-ring pulse-ring-2"></div>
        <div className="pulse-ring pulse-ring-3"></div>

        {/* Connection lines */}
        <div className="connection-line line-1"></div>
        <div className="connection-line line-2"></div>
        <div className="connection-line line-3"></div>

        {/* Blockchain Network Nodes */}
        <div className="blockchain-node node-1"></div>
        <div className="blockchain-node node-2"></div>
        <div className="blockchain-node node-3"></div>
        <div className="blockchain-node node-4"></div>
        <div className="blockchain-node node-5"></div>
        <div className="blockchain-node node-6"></div>
        <div className="blockchain-node node-7"></div>
        <div className="blockchain-node node-8"></div>
        <div className="blockchain-node node-9"></div>
        <div className="blockchain-node node-10"></div>
        <div className="blockchain-node node-11"></div>
        <div className="blockchain-node node-12"></div>

        {/* Data Blocks */}
        <div className="data-block block-1"></div>
        <div className="data-block block-2"></div>
        <div className="data-block block-3"></div>
        <div className="data-block block-4"></div>
        <div className="data-block block-5"></div>
        <div className="data-block block-6"></div>
        <div className="data-block block-7"></div>
        <div className="data-block block-8"></div>

        {/* Network Connection Lines */}
        <div className="network-line net-line-1"></div>
        <div className="network-line net-line-2"></div>
        <div className="network-line net-line-3"></div>
        <div className="network-line net-line-4"></div>
        <div className="network-line net-line-5"></div>
        <div className="network-line net-line-6"></div>
        <div className="network-line net-line-7"></div>
        <div className="network-line net-line-8"></div>

        {/* Chain Links */}
        <div className="chain-link link-1"></div>
        <div className="chain-link link-2"></div>
        <div className="chain-link link-3"></div>
        <div className="chain-link link-4"></div>
        <div className="chain-link link-5"></div>
        <div className="chain-link link-6"></div>
        <div className="chain-link link-7"></div>
        <div className="chain-link link-8"></div>
        <div className="chain-link link-9"></div>
        <div className="chain-link link-10"></div>
        <div className="chain-link link-11"></div>
        <div className="chain-link link-12"></div>
        <div className="chain-link link-13"></div>
        <div className="chain-link link-14"></div>
        <div className="chain-link link-15"></div>

        {/* Crypto Hexagons */}
        <div className="crypto-hex hex-1"></div>
        <div className="crypto-hex hex-2"></div>
        <div className="crypto-hex hex-3"></div>
        <div className="crypto-hex hex-4"></div>

        {/* Data Streams */}
        <div className="data-stream stream-1"></div>
        <div className="data-stream stream-2"></div>
        <div className="data-stream stream-3"></div>

        {/* Oracle Symbols */}
        <div className="oracle-symbol oracle-1"></div>
        <div className="oracle-symbol oracle-2"></div>
        <div className="oracle-symbol oracle-3"></div>

        {/* Falling Elements */}
        <div className="falling-element falling-1"></div>
        <div className="falling-element falling-2"></div>
        <div className="falling-element falling-3"></div>
        <div className="falling-element falling-4"></div>
        <div className="falling-element falling-5"></div>
        <div className="falling-element falling-6"></div>
        <div className="falling-element falling-7"></div>
        <div className="falling-element falling-8"></div>
        <div className="falling-element falling-9"></div>

        {/* Lightning Effects */}
        <div className="lightning-flash lightning-1"></div>
        <div className="lightning-flash lightning-2"></div>
        <div className="lightning-flash lightning-3"></div>

        {/* Lightning Branches */}
        <div className="lightning-branch branch-1"></div>
        <div className="lightning-branch branch-2"></div>
        <div className="lightning-branch branch-3"></div>
        <div className="lightning-branch branch-4"></div>
        <div className="lightning-branch branch-5"></div>
        <div className="lightning-branch branch-6"></div>

        {/* Glow Pulses */}
        <div className="glow-pulse glow-1"></div>
        <div className="glow-pulse glow-2"></div>
        <div className="glow-pulse glow-3"></div>

        {/* Energy Trails */}
        <div className="energy-trail trail-1"></div>
        <div className="energy-trail trail-2"></div>
        <div className="energy-trail trail-3"></div>

        {/* Smart Contracts */}
        <div className="smart-contract contract-1"></div>
        <div className="smart-contract contract-2"></div>
        <div className="smart-contract contract-3"></div>
        <div className="smart-contract contract-4"></div>

        {/* Transaction Flow */}
        <div className="transaction-flow tx-1"></div>
        <div className="transaction-flow tx-2"></div>
        <div className="transaction-flow tx-3"></div>
        <div className="transaction-flow tx-4"></div>
        <div className="transaction-flow tx-5"></div>

        {/* Blockchain Hash */}
        <div className="blockchain-hash hash-1"></div>
        <div className="blockchain-hash hash-2"></div>
        <div className="blockchain-hash hash-3"></div>
        <div className="blockchain-hash hash-4"></div>
        <div className="blockchain-hash hash-5"></div>
      </div>

      {/* Navigation */}
      <nav className="relative z-50 bg-black/80 backdrop-blur-sm border-b border-gray-800/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-r from-blue-600 to-blue-500 rounded-lg flex items-center justify-center">
                <TrendingUp className="text-white text-lg" />
              </div>
              <div>
                <span className="text-xl font-bold text-white">PerpChain</span>
                <span className="text-xl font-light text-blue-400 ml-1">Trading</span>
              </div>
            </div>
            <div className="hidden md:block">
              <div className="text-sm text-slate-400">
                Cross-Chain Perpetual Trading Platform
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative z-10 min-h-screen flex items-center justify-center px-4 sm:px-6 lg:px-8">
        <div className="max-w-6xl mx-auto text-center">
          <motion.div 
            className="mb-8"
            animate={{ y: [0, -10, 0] }}
            transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
          >
            <div className="inline-flex items-center space-x-4 mb-6">
              <div className="w-16 h-16 bg-gradient-to-r from-blue-600 to-blue-500 rounded-2xl flex items-center justify-center shadow-2xl">
                <TrendingUp className="text-white text-2xl" />
              </div>
              <div className="text-left">
                <h1 className="text-2xl sm:text-3xl font-bold text-white">PerpChain</h1>
                <h1 className="text-2xl sm:text-3xl font-light text-blue-400">Trading</h1>
              </div>
            </div>
          </motion.div>

          <motion.h1 
            className="text-4xl sm:text-5xl lg:text-7xl font-bold mb-6"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
          >
            <span className="bg-gradient-to-r from-slate-100 to-white bg-clip-text text-transparent">The Future of</span>
            <span className="bg-gradient-to-r from-cyan-400 via-blue-500 to-purple-600 bg-clip-text text-transparent animate-gradient block">
              Cross-Chain
            </span>
            <span className="bg-gradient-to-r from-purple-500 via-pink-500 to-cyan-400 bg-clip-text text-transparent animate-gradient">
              Perpetual
            </span>
            <span className="bg-gradient-to-r from-slate-100 to-white bg-clip-text text-transparent">Trading</span>
          </motion.h1>

          <motion.p 
            className="text-lg sm:text-xl lg:text-2xl bg-gradient-to-r from-slate-200 via-slate-100 to-slate-200 bg-clip-text text-transparent mb-8 max-w-4xl mx-auto leading-relaxed"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
          >
            Trade perpetual futures across multiple blockchains with up to 50x leverage. 
            Powered by Chainlink CCIP for seamless cross-chain deposits, withdrawals, and position management.
          </motion.p>

          <motion.div 
            className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-8"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.6 }}
          >
            <button
              onClick={handleLaunchApp}
              className="px-8 py-4 bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-700 hover:to-blue-600 text-white font-semibold rounded-xl shadow-2xl transform hover:scale-105 transition-all duration-300 flex items-center space-x-2"
            >
              <span>Launch Trading App</span>
              <ChevronDown className="w-5 h-5 transform rotate-90" />
            </button>
            
            <button
              onClick={handleViewDemo}
              className="px-8 py-4 bg-transparent border-2 border-blue-500 hover:bg-blue-500/10 text-blue-400 hover:text-white font-semibold rounded-xl transition-all duration-300 flex items-center space-x-2"
            >
              <span>View Demo</span>
              <Globe className="w-5 h-5" />
            </button>
          </motion.div>

          <motion.div 
            className="text-sm text-slate-400"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.8, delay: 0.8 }}
          >
            Powered by Chainlink CCIP • Multi-chain support • Up to 50x leverage • Real-time liquidation
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section className="relative z-10 py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <motion.div 
            className="text-center mb-16"
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
          >
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold mb-6">
              <span className="bg-gradient-to-r from-slate-100 to-white bg-clip-text text-transparent">
                Advanced Features for
              </span>
              <span className="bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent block">
                Professional Traders
              </span>
            </h2>
            <p className="text-lg text-slate-300 max-w-3xl mx-auto">
              Everything you need for sophisticated cross-chain perpetual trading with institutional-grade security
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                icon: <Network className="w-8 h-8" />,
                title: "Cross-Chain Trading",
                description: "Trade perpetual futures across Ethereum, Avalanche, BNB Chain, and other major networks"
              },
              {
                icon: <TrendingUp className="w-8 h-8" />,
                title: "High Leverage",
                description: "Access up to 50x leverage with advanced risk management and liquidation protection"
              },
              {
                icon: <Shield className="w-8 h-8" />,
                title: "Chainlink Security",
                description: "Bank-grade security powered by Chainlink CCIP and Data Streams for real-time price feeds"
              },
              {
                icon: <Zap className="w-8 h-8" />,
                title: "Instant Execution",
                description: "Lightning-fast order execution with sub-second latency and minimal slippage"
              },
              {
                icon: <Database className="w-8 h-8" />,
                title: "Real-time Data",
                description: "Access high-frequency market data and off-chain information via Chainlink oracles"
              },
              {
                icon: <Lock className="w-8 h-8" />,
                title: "Automated Liquidation",
                description: "Advanced liquidation engine with circuit breakers and automated risk management"
              }
            ].map((feature, index) => (
              <motion.div
                key={index}
                className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-2xl p-6 hover:bg-gray-800/50 transition-all duration-300"
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: index * 0.1 }}
                viewport={{ once: true }}
              >
                <div className="w-12 h-12 bg-gradient-to-r from-blue-600 to-blue-500 rounded-xl flex items-center justify-center mb-4">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-semibold text-white mb-2">{feature.title}</h3>
                <p className="text-slate-300">{feature.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="relative z-10 py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
          >
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold mb-6">
              <span className="bg-gradient-to-r from-slate-100 to-white bg-clip-text text-transparent">
                Ready to Trade the
              </span>
              <span className="bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent block">
                Future of DeFi?
              </span>
            </h2>
            <p className="text-lg text-slate-300 mb-8 max-w-2xl mx-auto">
              Join thousands of traders already using PerpChain for cross-chain perpetual trading
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button
                onClick={handleLaunchApp}
                className="px-8 py-4 bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-700 hover:to-blue-600 text-white font-semibold rounded-xl shadow-2xl transform hover:scale-105 transition-all duration-300"
              >
                Start Trading Now
              </button>
              <button
                onClick={handleConnectWallet}
                className="px-8 py-4 bg-transparent border-2 border-blue-500 hover:bg-blue-500/10 text-blue-400 hover:text-white font-semibold rounded-xl transition-all duration-300 flex items-center justify-center space-x-2"
              >
                <Wallet className="w-5 h-5" />
                <span>Connect Wallet</span>
              </button>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 py-12 px-4 sm:px-6 lg:px-8 border-t border-gray-800">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="flex items-center space-x-3 mb-4 md:mb-0">
              <div className="w-8 h-8 bg-gradient-to-r from-blue-600 to-blue-500 rounded-lg flex items-center justify-center">
                <TrendingUp className="text-white text-sm" />
              </div>
              <div>
                <span className="text-lg font-bold text-white">PerpChain</span>
                <span className="text-lg font-light text-blue-400 ml-1">Trading</span>
              </div>
            </div>
            <div className="text-sm text-slate-400">
              © 2024 PerpChain Trading. Built with ❤️ for the DeFi community.
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
} 