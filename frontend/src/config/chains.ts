import { defineChain } from 'viem';

export const citrea = defineChain({
  id: 4114,
  name: 'Citrea',
  nativeCurrency: {
    name: 'cBTC',
    symbol: 'cBTC',
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ['https://rpc.citrea.xyz'],
    },
    public: {
      http: ['https://rpc.citrea.xyz'],
    },
  },
  blockExplorers: {
    default: {
      name: 'Citrea Explorer',
      url: 'https://explorer.citrea.xyz',
    },
  },
});
