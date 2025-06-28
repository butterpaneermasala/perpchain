import React from 'react';

const CONTRACTS = [
  'DataStreamOracle',
  'CrossChainVault',
  'PositionManager',
  'PerpetualTrading',
  'LiquidationEngine',
  'CrossChainReceiver',
];

export default function Sidebar({ selected, onSelect }: { selected: string, onSelect: (name: string) => void }) {
  return (
    <nav style={{ width: 220, background: '#232946', color: '#fff', padding: 32, display: 'flex', flexDirection: 'column', gap: 24, minHeight: '100vh', zIndex: 2 }}>
      <div style={{ fontSize: 28, fontWeight: 900, marginBottom: 32, letterSpacing: -2 }}>PerpChain</div>
      <h2 style={{ fontSize: 20, margin: '16px 0 8px 0' }}>Contracts</h2>
      <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
        {CONTRACTS.map(name => (
          <li key={name} style={{ marginBottom: 8 }}>
            <button
              onClick={() => onSelect(name)}
              style={{
                background: selected === name ? '#eebbc3' : 'transparent',
                color: selected === name ? '#232946' : '#fff',
                border: 'none',
                borderRadius: 8,
                padding: '0.7em 1.1em',
                fontWeight: 700,
                fontSize: 16,
                cursor: 'pointer',
                textAlign: 'left',
                width: '100%',
              }}
            >
              {name}
            </button>
          </li>
        ))}
      </ul>
      <div style={{ marginTop: 32, background: '#eebbc3', color: '#232946', borderRadius: 12, padding: 16 }}>
        <h3 style={{ fontSize: 16, margin: '0 0 8px 0' }}>Guide</h3>
        <p style={{ fontSize: 14, margin: 0 }}>
          Select a contract to interact with. Each page provides a simple UI and a guide to help you understand and use the contract.
        </p>
      </div>
    </nav>
  );
}
