import { HELIX_LENS_ABI } from '@/abi/HelixLens.json';
import { HELIX_VAULT_ABI } from '@/abi/HelixVault.json';
import { HLX_TOKEN_ABI } from '@/abi/HLXToken.json';
import { REWARD_DISTRIBUTOR_ABI } from '@/abi/RewardDistributor.json';
import { STRATEGY_ABI } from '@/abi/AutoCompoundClStrategy.json';

import { CONTRACTS } from '@/config/contracts';

export {
  HELIX_LENS_ABI,
  HELIX_VAULT_ABI,
  HLX_TOKEN_ABI,
  REWARD_DISTRIBUTOR_ABI,
  STRATEGY_ABI,
};

export const contractAbis = {
  helixVault: HELIX_VAULT_ABI,
  strategy: STRATEGY_ABI,
  hlxToken: HLX_TOKEN_ABI,
  rewardDistributor: REWARD_DISTRIBUTOR_ABI,
  helixLens: HELIX_LENS_ABI,
} as const;

export const contractAddresses = CONTRACTS;
