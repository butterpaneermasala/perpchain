
import React, { useState } from 'react';
import { Toaster } from 'sonner';
import { Web3Provider } from './contexts/Web3Context';
import Sidebar from './components/Sidebar';
import ContractPage from './components/ContractPage';
import Dashboard from './components/Dashboard';
import TradingInterface from './components/TradingInterface';
import { UserGuide } from './components/UserGuide';
import { loadContractAddresses } from './utils/contracts';
import './index.css';
import './styles/neobrutalism.css';

const CONTRACTS = [
  'DataStreamOracle',
  'CrossChainVault',
  'PositionManager',
  'PerpetualTrading',
  'LiquidationEngine',
  'CrossChainReceiver',
];

function App() {
  const [selected, setSelected] = useState('Dashboard');
  const [addresses, setAddresses] = React.useState<Record<string, string>>({});

  React.useEffect(() => {
    loadContractAddresses().then(setAddresses);
  }, []);

  const renderContent = () => {
    if (selected === 'Dashboard') {
      return <Dashboard contracts={CONTRACTS} addresses={addresses} />;
    }
    
    if (selected === 'Trading') {
      return <TradingInterface />;
    }

    if (selected === 'Guide') {
      return <UserGuide />;
    }
    
    if (addresses[selected]) {
      return <ContractPage name={selected} address={addresses[selected]} />;
    }
    
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-2xl font-bold text-[#666]">Loading contract info...</div>
      </div>
    );
  };

  return (
    <Web3Provider>
      <div className="flex min-h-screen bg-[#f7f7f7]">
        <Sidebar 
          selected={selected} 
          onSelect={setSelected} 
          contracts={CONTRACTS}
        />
        <main className="flex-1 min-h-screen">
          {renderContent()}
        </main>
        <Toaster 
          position="top-right" 
          toastOptions={{
            style: {
              background: '#232946',
              color: '#43d9ad',
              border: '4px solid #43d9ad',
              fontWeight: 'bold'
            }
          }}
        />
      </div>
    </Web3Provider>
  );
}

export default App;
