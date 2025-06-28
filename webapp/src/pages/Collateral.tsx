import React, { useState, useEffect } from 'react';
import { Box, Heading, Text, VStack, Button, Input, useToast } from '@chakra-ui/react';
import { useAccount } from 'wagmi';
import { ethers } from 'ethers';
import ERC20ABI from '../abis/DataStreamOracle.json'; // Replace with actual ERC20 ABI if available
import VaultABI from '../abis/CrossChainVault.json';
import { CONTRACTS } from '../contracts';

export default function Collateral() {
  const { address } = useAccount();
  const [erc20Balance, setErc20Balance] = useState<string>('0');
  const [vaultBalance, setVaultBalance] = useState<string>('0');
  const [amount, setAmount] = useState('');
  const [loading, setLoading] = useState(false);
  const toast = useToast();

  useEffect(() => {
    async function fetchBalances() {
      if (!address) return;
      const provider = new ethers.BrowserProvider(window.ethereum);
      const erc20 = new ethers.Contract(CONTRACTS.mockERC20, ERC20ABI, provider);
      const vault = new ethers.Contract(CONTRACTS.crossChainVault, VaultABI, provider);
      const bal = await erc20.balanceOf(address);
      setErc20Balance(ethers.formatUnits(bal, 18));
      const vbal = await vault.balances(address);
      setVaultBalance(ethers.formatUnits(vbal, 18));
    }
    fetchBalances();
  }, [address, loading]);

  async function approve() {
    setLoading(true);
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const erc20 = new ethers.Contract(CONTRACTS.mockERC20, ERC20ABI, signer);
      const tx = await erc20.approve(CONTRACTS.crossChainVault, ethers.parseUnits(amount || '0', 18));
      await tx.wait();
      toast({ title: 'Approved!', status: 'success' });
    } catch (e) {
      toast({ title: 'Approve failed', status: 'error' });
    }
    setLoading(false);
  }

  async function deposit() {
    setLoading(true);
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const vault = new ethers.Contract(CONTRACTS.crossChainVault, VaultABI, signer);
      const tx = await vault.deposit(ethers.parseUnits(amount || '0', 18));
      await tx.wait();
      toast({ title: 'Deposited!', status: 'success' });
    } catch (e) {
      toast({ title: 'Deposit failed', status: 'error' });
    }
    setLoading(false);
  }

  async function withdraw() {
    setLoading(true);
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const vault = new ethers.Contract(CONTRACTS.crossChainVault, VaultABI, signer);
      const tx = await vault.withdraw(ethers.parseUnits(amount || '0', 18));
      await tx.wait();
      toast({ title: 'Withdrawn!', status: 'success' });
    } catch (e) {
      toast({ title: 'Withdraw failed', status: 'error' });
    }
    setLoading(false);
  }

  return (
    <Box p={8} bg="white" borderRadius="lg" boxShadow="md">
      <Heading size="lg" mb={4}>Collateral</Heading>
      <VStack align="start">
        <Text>ERC20 Balance: <b>{erc20Balance}</b></Text>
        <Text>Vault Balance: <b>{vaultBalance}</b></Text>
        <Input placeholder="Amount" maxW="200px" value={amount} onChange={e => setAmount(e.target.value)} />
        <Button colorScheme="teal" onClick={approve} isLoading={loading}>Approve</Button>
        <Button colorScheme="blue" onClick={deposit} isLoading={loading}>Deposit</Button>
        <Button colorScheme="orange" onClick={withdraw} isLoading={loading}>Withdraw</Button>
      </VStack>
    </Box>
  );
} 