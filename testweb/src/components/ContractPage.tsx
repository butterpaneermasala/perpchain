import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useWallet } from '../utils/useWallet';
import { loadAbi } from '../utils/contracts';

export default function ContractPage({ name, address }: { name: string, address: string }) {
  const { provider, signer, address: userAddress, connect } = useWallet();
  const [abi, setAbi] = useState<any>(null);
  const [contract, setContract] = useState<ethers.Contract | null>(null);
  const [functions, setFunctions] = useState<any[]>([]);
  const [outputs, setOutputs] = useState<Record<string, any>>({});
  const [inputs, setInputs] = useState<Record<string, any>>({});

  useEffect(() => {
    loadAbi(name).then(setAbi);
  }, [name]);

  useEffect(() => {
    if (abi && signer && address) {
      setContract(new ethers.Contract(address, abi, signer));
      setFunctions(abi.filter((f: any) => f.type === 'function'));
    }
  }, [abi, signer, address]);

  const handleInput = (fname: string, idx: number, value: string) => {
    setInputs(inputs => ({ ...inputs, [fname]: { ...inputs[fname], [idx]: value } }));
  };

  const callFunction = async (f: any) => {
    if (!contract) return;
    const args = (inputs[f.name] ? Object.values(inputs[f.name]) : []);
    try {
      let result;
      if (f.stateMutability === 'view' || f.stateMutability === 'pure') {
        result = await contract[f.name](...args);
      } else {
        const tx = await contract[f.name](...args);
        result = await tx.wait();
      }
      setOutputs(o => ({ ...o, [f.name]: JSON.stringify(result, null, 2) }));
    } catch (e: any) {
      setOutputs(o => ({ ...o, [f.name]: e.message }));
    }
  };

  return (
    <div style={{ maxWidth: 700, margin: '0 auto', padding: 32 }}>
      <h1 style={{ fontSize: 32, fontWeight: 900, marginBottom: 8 }}>{name}</h1>
      <div style={{ fontSize: 14, marginBottom: 16, color: '#888' }}>Address: {address}</div>
      <div style={{ background: '#eebbc3', color: '#232946', borderRadius: 12, padding: 16, marginBottom: 24 }}>
        <h2 style={{ fontSize: 20, margin: '0 0 8px 0' }}>How to use</h2>
        <p>This page lets you interact with the {name} contract. Use the forms below to call contract functions. Read-only functions show results instantly. Write functions require wallet connection and will prompt for transaction approval.</p>
      </div>
      <div style={{ marginBottom: 24 }}>
        {userAddress ? (
          <span style={{ color: '#43d9ad', fontWeight: 700 }}>Connected: {userAddress}</span>
        ) : (
          <button onClick={connect} style={{ background: '#232946', color: '#eebbc3', border: 'none', borderRadius: 8, padding: '0.7em 1.2em', fontWeight: 700, fontSize: 16, cursor: 'pointer' }}>Connect Wallet</button>
        )}
      </div>
      <div>
        {functions.map(f => (
          <div key={f.name} style={{ background: '#232946', color: '#fff', borderRadius: 10, padding: 18, marginBottom: 18, boxShadow: '4px 4px 0 #eebbc3' }}>
            <div style={{ fontWeight: 700, fontSize: 18 }}>{f.name}</div>
            <form onSubmit={e => { e.preventDefault(); callFunction(f); }}>
              {f.inputs.map((inp: any, idx: number) => (
                <input
                  key={idx}
                  type="text"
                  placeholder={inp.name || `arg${idx}`}
                  value={inputs[f.name]?.[idx] || ''}
                  onChange={e => handleInput(f.name, idx, e.target.value)}
                  style={{ margin: '8px 8px 8px 0', padding: 8, borderRadius: 6, border: '2px solid #eebbc3', background: '#fff', color: '#232946', fontWeight: 600 }}
                  required
                />
              ))}
              <button type="submit" style={{ background: '#eebbc3', color: '#232946', border: 'none', borderRadius: 8, padding: '0.5em 1.1em', fontWeight: 700, fontSize: 15, cursor: 'pointer', marginTop: 8 }}>
                {f.stateMutability === 'view' || f.stateMutability === 'pure' ? 'Read' : 'Write'}
              </button>
            </form>
            {outputs[f.name] && (
              <pre style={{ background: '#fff', color: '#232946', borderRadius: 6, padding: 10, marginTop: 10, fontSize: 13, overflowX: 'auto' }}>{outputs[f.name]}</pre>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
