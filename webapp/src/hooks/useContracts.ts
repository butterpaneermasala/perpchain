import { useMemo } from 'react';
import { useAccount, useSigner, useProvider } from 'wagmi';
import { Contract } from 'ethers';
import DataStreamOracleABI from '../abis/DataStreamOracle.json';
import PositionManagerABI from '../abis/PositionManager.json';
import PerpetualTradingABI from '../abis/PerpetualTrading.json';
import LiquidationEngineABI from '../abis/LiquidationEngine.json';
import CrossChainVaultABI from '../abis/CrossChainVault.json';
import { CONTRACTS } from '../contracts';

function useContract(address: string, abi: any) {
  const { data: signer } = useSigner();
  const provider = useProvider();
  return useMemo(() => {
    if (!address || !abi) return null;
    return new Contract(address, abi, signer ?? provider);
  }, [address, abi, signer, provider]);
}

export function useDataStreamOracle() {
  return useContract(CONTRACTS.dataStreamOracle, DataStreamOracleABI);
}
export function usePositionManager() {
  return useContract(CONTRACTS.positionManager, PositionManagerABI);
}
export function usePerpetualTrading() {
  return useContract(CONTRACTS.perpetualTrading, PerpetualTradingABI);
}
export function useLiquidationEngine() {
  return useContract(CONTRACTS.liquidationEngine, LiquidationEngineABI);
}
export function useCrossChainVault() {
  return useContract(CONTRACTS.crossChainVault, CrossChainVaultABI);
} 