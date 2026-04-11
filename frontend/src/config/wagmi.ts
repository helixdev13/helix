import { createConfig } from 'wagmi';
import { injected, walletConnect } from 'wagmi/connectors';
import { fallback, http } from 'viem';

import { citrea } from './chains';

const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? 'YOUR_PROJECT_ID';
const walletConnectConnector =
  projectId && projectId !== 'YOUR_PROJECT_ID'
    ? walletConnect({
        projectId,
        showQrModal: true,
        metadata: {
          name: 'Helix',
          description: 'Citrea Yield Optimizer',
          url: 'https://helix.xyz',
          icons: [],
        },
      })
    : null;

const citreaFallbackRpc = process.env.NEXT_PUBLIC_CITREA_FALLBACK_RPC_URL;
const transport = citreaFallbackRpc
  ? fallback([http('https://rpc.mainnet.citrea.xyz'), http(citreaFallbackRpc)])
  : http('https://rpc.mainnet.citrea.xyz');

export const config = createConfig({
  chains: [citrea],
  transports: {
    [citrea.id]: transport,
  },
  connectors: [injected(), ...(walletConnectConnector ? [walletConnectConnector] : [])],
  ssr: false,
});
