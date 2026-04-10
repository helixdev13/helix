export const HELIX_LENS_ABI = [
  {
    "type": "function",
    "name": "getCompoundStrategyView",
    "inputs": [
      {
        "name": "vault",
        "type": "address",
        "internalType": "contract HelixVault"
      }
    ],
    "outputs": [
      {
        "name": "view_",
        "type": "tuple",
        "internalType": "struct HelixLens.CompoundStrategyView",
        "components": [
          {
            "name": "vault",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "strategy",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "adapter",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "performanceFeeBps",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "rewardRatioBps",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "bountyBps",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "hlxMintRate",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "minimumProfitThreshold",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "compoundCooldown",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "lastCompoundTimestamp",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "feeRecipient",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "hlxToken",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "rewardDistributor",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "totalIdle",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "totalDeployedAssets",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "totalAssets",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "rebalancePaused",
            "type": "bool",
            "internalType": "bool"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getVaultView",
    "inputs": [
      {
        "name": "vault",
        "type": "address",
        "internalType": "contract HelixVault"
      }
    ],
    "outputs": [
      {
        "name": "view_",
        "type": "tuple",
        "internalType": "struct HelixLens.VaultView",
        "components": [
          {
            "name": "vault",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "asset",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "guardian",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "strategy",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "riskEngine",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "totalAssets",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "totalIdle",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "totalStrategyAssets",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "depositCap",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "maxAllocationBps",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "paused",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "withdrawOnly",
            "type": "bool",
            "internalType": "bool"
          }
        ]
      }
    ],
    "stateMutability": "view"
  }
] as const;
