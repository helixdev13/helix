import { getDefaultConfig } from '@rainbow-me/rainbowkit';

import { citrea } from './chains';

export const config = getDefaultConfig({
  appName: 'Helix',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? 'YOUR_PROJECT_ID',
  chains: [citrea],
  ssr: true,
});
