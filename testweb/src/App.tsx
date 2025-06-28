import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
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
import './landing.css';

// Import the landing page
import LandingPage from './landing/pages/Home';

const CONTRACTS = [
  'DataStreamOracle',
  'CrossChainVault',
  'PositionManager',
  'PerpetualTrading',
  'LiquidationEngine',
  'CrossChainReceiver',
  'CrossChainLendingPool',
];

// Main App Component (the trading interface)
function MainApp() {
  const [selected, setSelected] = React.useState('Dashboard');
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
    
    if (CONTRACTS.includes(selected)) {
      return <ContractPage name={selected} address={addresses[selected] || ''} />;
    }
    
    return null;
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

// Root App Component with Routing
function App() {
  return (
    <Router>
      <Routes>
        {/* Landing page as the default route */}
        <Route path="/" element={<LandingPage />} />
        
        {/* Main app route */}
        <Route path="/app" element={<MainApp />} />
        
        {/* Redirect any unknown routes to landing page */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
