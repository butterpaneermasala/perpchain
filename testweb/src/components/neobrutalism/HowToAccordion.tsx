import React from 'react';
import Accordion, { AccordionItem } from './Accordion';

const HowToAccordion: React.FC = () => (
  <Accordion>
    <AccordionItem title="1. Connect your wallet">
      Click the “Connect Wallet” button in the top right. We support MetaMask and WalletConnect.
    </AccordionItem>
    <AccordionItem title="2. Deposit collateral">
      Go to the “Portfolio” tab and click “Deposit”. Enter the amount and confirm the transaction.
    </AccordionItem>
    <AccordionItem title="3. Trade perpetuals">
      Navigate to “Trade”, select your market, and open a position.
    </AccordionItem>
    <AccordionItem title="4. Withdraw funds">
      After trading, withdraw your collateral from the “Portfolio” tab.
    </AccordionItem>
    <AccordionItem title="What is PerpChain?">
      PerpChain is a cross-chain perpetual trading platform. It lets you trade perpetual contracts with leverage, using decentralized smart contracts. All trades, deposits, and withdrawals are handled on-chain.
    </AccordionItem>
  </Accordion>
);

export default HowToAccordion; 