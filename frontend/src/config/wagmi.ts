import { createConfig, http } from 'wagmi';
import { injected, walletConnect } from 'wagmi/connectors';

import { citrea } from './chains';

const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? 'YOUR_PROJECT_ID';

export const config = createConfig({
  chains: [citrea],
  transports: {
    [citrea.id]: http('https://rpc.citrea.xyz'),
  },
  connectors: [
    injected(),
    walletConnect({
      projectId,
      showQrModal: true,
      metadata: {
        name: 'Helix',
        description: 'Citrea Yield Optimizer',
        url: 'https://helix.xyz',
        icons: [],
      },
    }),
  ],
  ssr: true,
});
