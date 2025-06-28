import React from 'react';
import { BarChart3, Home, Settings, Zap, BookOpen, Wallet } from 'lucide-react';

interface SidebarProps {
  selected: string;
  onSelect: (name: string) => void;
  contracts: string[];
}

export default function Sidebar({ selected, onSelect, contracts }: SidebarProps) {
  const mainItems = [
    { id: 'Dashboard', label: 'Dashboard', icon: Home },
    { id: 'Trading', label: 'Trading', icon: BarChart3 },
    { id: 'Guide', label: 'User Guide', icon: BookOpen },
  ];

  return (
    <nav className="w-80 bg-[#232946] text-white p-8 flex flex-col gap-6 min-h-screen border-r-8 border-[#43d9ad] relative">
      {/* Logo */}
      <div className="mb-8">
        <div className="text-4xl font-black mb-2 tracking-tight flex items-center gap-3">
          <Zap className="h-10 w-10 text-[#43d9ad]" />
          PerpChain
        </div>
        <div className="text-[#43d9ad] font-bold text-sm">Cross-Chain Perpetuals</div>
      </div>
      
      {/* Main Navigation */}
      <div className="space-y-2">
        {mainItems.map(item => (
          <button
            key={item.id}
            onClick={() => onSelect(item.id)}
            className={`w-full flex items-center gap-4 p-4 rounded-lg border-4 font-bold text-lg transition-all ${
              selected === item.id
                ? 'bg-[#43d9ad] text-[#232946] border-[#43d9ad] shadow-[4px_4px_0px_0px_#3b82f6]'
                : 'bg-transparent text-white border-transparent hover:bg-[#43d9ad] hover:text-[#232946] hover:border-[#43d9ad] hover:shadow-[4px_4px_0px_0px_#3b82f6]'
            }`}
          >
            <item.icon className="h-6 w-6" />
            {item.label}
          </button>
        ))}
      </div>

      {/* Contracts Section */}
      <div className="mt-8">
        <h2 className="text-[#43d9ad] font-black text-lg mb-4 flex items-center gap-2">
          <Settings className="h-5 w-5" />
          Smart Contracts
        </h2>
        <div className="space-y-2">
          {contracts.map(name => (
            <button
              key={name}
              onClick={() => onSelect(name)}
              className={`w-full text-left p-3 rounded-lg border-2 font-bold transition-all ${
                selected === name
                  ? 'bg-[#43d9ad] text-[#232946] border-[#43d9ad] shadow-[2px_2px_0px_0px_#3b82f6]'
                  : 'bg-transparent text-white border-transparent hover:bg-[#43d9ad] hover:text-[#232946] hover:border-[#43d9ad] hover:shadow-[2px_2px_0px_0px_#3b82f6]'
              }`}
            >
              {name}
            </button>
          ))}
        </div>
      </div>

      {/* Info Box */}
      <div className="mt-auto p-6 bg-[#43d9ad] text-[#232946] border-4 border-[#3b82f6] rounded-lg shadow-[4px_4px_0px_0px_#3b82f6]">
        <h3 className="font-black text-lg mb-3">🚀 Quick Start</h3>
        <p className="font-bold text-sm leading-relaxed">
          • Check the User Guide for tutorials<br />
          • Connect wallet to start trading<br />
          • Deposit collateral before opening positions<br />
          • Start with low leverage (5x-10x)
        </p>
      </div>
    </nav>
  );
}
