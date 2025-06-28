import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useWeb3 } from '../contexts/Web3Context';
import { loadAbi } from '../utils/contracts';
import { Card } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Code, Play, Eye } from 'lucide-react';
import { WalletConnection } from './WalletConnection';

interface ContractPageProps {
  name: string;
  address: string;
}

interface AbiFunction {
  type: string;
  name: string;
  inputs: Array<{
    name: string;
    type: string;
  }>;
  stateMutability: string;
}

export default function ContractPage({ name, address }: ContractPageProps) {
  const { provider, signer, account } = useWeb3();
  const [abi, setAbi] = useState<AbiFunction[] | null>(null);
  const [contract, setContract] = useState<ethers.Contract | null>(null);
  const [functions, setFunctions] = useState<AbiFunction[]>([]);
  const [outputs, setOutputs] = useState<Record<string, string>>({});
  const [inputs, setInputs] = useState<Record<string, Record<number, string>>>({});
  const [loading, setLoading] = useState<Record<string, boolean>>({});

  useEffect(() => {
    loadAbi(name).then(setAbi).catch(console.error);
  }, [name]);

  useEffect(() => {
    if (abi && signer && address) {
      const contractInstance = new ethers.Contract(address, abi, signer);
      setContract(contractInstance);
      setFunctions(abi.filter((f: AbiFunction) => f.type === 'function'));
    }
  }, [abi, signer, address]);

  const handleInput = (fname: string, idx: number, value: string) => {
    setInputs(inputs => ({ ...inputs, [fname]: { ...inputs[fname], [idx]: value } }));
  };

  const callFunction = async (f: AbiFunction) => {
    if (!contract) return;
    
    setLoading(prev => ({ ...prev, [f.name]: true }));
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
    } catch (e: unknown) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      setOutputs(o => ({ ...o, [f.name]: `Error: ${errorMessage}` }));
    } finally {
      setLoading(prev => ({ ...prev, [f.name]: false }));
    }
  };

  const isReadFunction = (f: AbiFunction) => f.stateMutability === 'view' || f.stateMutability === 'pure';

  return (
    <div className="max-w-4xl mx-auto p-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-black mb-2 text-[#232946] flex items-center gap-4">
          <Code className="h-10 w-10 text-[#eebbc3]" />
          {name}
        </h1>
        <p className="text-[#666] font-bold mb-4">Contract Address: {address}</p>
        
        <Card className="p-6 border-4 border-[#232946] shadow-[8px_8px_0px_0px_#eebbc3] bg-gradient-to-r from-[#eebbc3] to-[#f7f7f7]">
          <h2 className="text-2xl font-black mb-4 text-[#232946]">How to Use</h2>
          <p className="text-[#666] leading-relaxed">
            This page lets you interact with the {name} contract directly. 
            <span className="font-bold"> Read functions</span> show data instantly, while 
            <span className="font-bold"> write functions</span> require wallet connection and gas fees.
          </p>
        </Card>
      </div>

      {/* Wallet Connection */}
      <div className="mb-8">
        <WalletConnection />
      </div>

      {/* Functions */}
      {functions.length > 0 ? (
        <div className="space-y-6">
          <h2 className="text-3xl font-black text-[#232946] mb-6">Contract Functions</h2>
          {functions.map(f => (
            <Card key={f.name} className={`p-6 border-4 border-[#232946] shadow-[8px_8px_0px_0px_#eebbc3] ${
              isReadFunction(f) ? 'bg-blue-50' : 'bg-orange-50'
            }`}>
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  {isReadFunction(f) ? (
                    <Eye className="h-6 w-6 text-blue-600" />
                  ) : (
                    <Play className="h-6 w-6 text-orange-600" />
                  )}
                  <h3 className="text-2xl font-black text-[#232946]">{f.name}</h3>
                </div>
                <div className={`px-3 py-1 rounded-lg border-2 border-[#232946] font-bold text-sm ${
                  isReadFunction(f) 
                    ? 'bg-blue-500 text-white' 
                    : 'bg-orange-500 text-white'
                }`}>
                  {isReadFunction(f) ? 'READ' : 'WRITE'}
                </div>
              </div>
              
              <form onSubmit={e => { e.preventDefault(); callFunction(f); }} className="space-y-4">
                {f.inputs && f.inputs.map((inp: { name: string; type: string }, idx: number) => (
                  <div key={idx}>
                    <label className="block font-bold text-[#232946] mb-2">
                      {inp.name || `Parameter ${idx + 1}`} ({inp.type})
                    </label>
                    <Input
                      type="text"
                      placeholder={`Enter ${inp.type} value`}
                      value={inputs[f.name]?.[idx] || ''}
                      onChange={e => handleInput(f.name, idx, e.target.value)}
                      className="border-4 border-[#232946] font-bold bg-white"
                      required
                    />
                  </div>
                ))}
                
                <Button 
                  type="submit" 
                  disabled={loading[f.name] || !account}
                  className={`w-full font-bold text-lg py-3 border-4 border-[#232946] shadow-[4px_4px_0px_0px_#232946] hover:shadow-[2px_2px_0px_0px_#232946] transition-all ${
                    isReadFunction(f)
                      ? 'bg-blue-500 hover:bg-blue-600 text-white'
                      : 'bg-orange-500 hover:bg-orange-600 text-white'
                  }`}
                >
                  {loading[f.name] ? 'Processing...' : (isReadFunction(f) ? 'Read Data' : 'Execute Transaction')}
                </Button>
              </form>
              
              {outputs[f.name] && (
                <div className="mt-6">
                  <h4 className="font-bold text-[#232946] mb-2">Result:</h4>
                  <pre className="bg-white border-4 border-[#232946] p-4 rounded-lg text-sm overflow-x-auto font-mono">
                    {outputs[f.name]}
                  </pre>
                </div>
              )}
            </Card>
          ))}
        </div>
      ) : (
        <Card className="p-8 text-center border-4 border-[#232946] shadow-[8px_8px_0px_0px_#eebbc3]">
          <h3 className="text-xl font-bold text-[#666] mb-4">
            {abi ? 'No functions found in this contract' : 'Loading contract functions...'}
          </h3>
          <p className="text-[#666]">
            {abi ? 'This contract may not have any public functions.' : 'Please wait while we load the contract ABI.'}
          </p>
        </Card>
      )}
    </div>
  );
}
