import React, { useState } from 'react';
import Sidebar from './components/Sidebar';
import ContractPage from './components/ContractPage';
import { loadContractAddresses } from './utils/contracts';
import './App.css';
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
  const [selected, setSelected] = useState(CONTRACTS[0]);
  const [addresses, setAddresses] = React.useState<Record<string, string>>({});

  React.useEffect(() => {
    loadContractAddresses().then(setAddresses);
  }, []);

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: '#f7f7f7' }}>
      <Sidebar selected={selected} onSelect={setSelected} />
      <main style={{ flex: 1, background: '#f7f7f7', minHeight: '100vh', padding: 0 }}>
        {addresses[selected] ? (
          <ContractPage name={selected} address={addresses[selected]} />
        ) : (
          <div style={{ padding: 48, color: '#888' }}>Loading contract info...</div>
        )}
      </main>
    </div>
  );
}

export default App;
