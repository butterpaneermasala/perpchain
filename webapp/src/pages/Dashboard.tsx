import React from 'react';
import { Box, Heading, Text, VStack, Code } from '@chakra-ui/react';
import { useAccount, useBalance } from 'wagmi';
import { CONTRACTS } from '../contracts';
import { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import ERC20ABI from '../abis/DataStreamOracle.json'; // Replace with actual ERC20 ABI if available

export default function Dashboard() {
  const { address, isConnected } = useAccount();
  const { data: ethBalance } = useBalance({ address });
  const [erc20Balance, setErc20Balance] = useState<string | null>(null);

  useEffect(() => {
    async function fetchERC20() {
      if (!address) return;
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(CONTRACTS.mockERC20, ERC20ABI, provider);
      const bal = await contract.balanceOf(address);
      setErc20Balance(ethers.formatUnits(bal, 18));
    }
    fetchERC20();
  }, [address]);

  return (
    <Box p={8} bg="white" borderRadius="lg" boxShadow="md">
      <Heading size="lg" mb={4}>Dashboard</Heading>
      <VStack align="start">
        <Text>Wallet: <Code>{isConnected ? address : 'Not connected'}</Code></Text>
        <Text>ETH Balance: <b>{ethBalance ? ethBalance.formatted : '--'}</b></Text>
        <Text>ERC20 Balance: <b>{erc20Balance ?? '--'}</b></Text>
        <Heading size="sm" mt={4}>Contract Addresses</Heading>
        {Object.entries(CONTRACTS).map(([name, addr]) => (
          <Text key={name}><b>{name}:</b> <Code>{addr}</Code></Text>
        ))}
      </VStack>
    </Box>
  );
} 