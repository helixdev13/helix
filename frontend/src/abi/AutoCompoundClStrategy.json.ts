export const STRATEGY_ABI = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "asset_",
        "type": "address",
        "internalType": "contract IERC20"
      },
      {
        "name": "vault_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "adapter_",
        "type": "address",
        "internalType": "contract IClAdapter"
      },
      {
        "name": "oracleRouter_",
        "type": "address",
        "internalType": "contract IOracleRouter"
      },
      {
        "name": "initialOwner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "strategist_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "guardian_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "feeRecipient_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "hlxToken_",
        "type": "address",
        "internalType": "contract HLXToken"
      },
      {
        "name": "rewardDistributor_",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "ASSET_TOKEN",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract IERC20"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "BPS_DENOMINATOR",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "VAULT",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "acceptOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "adapter",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "adapterValuation",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct Types.Valuation",
        "components": [
          {
            "name": "grossAssets",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "deployedAssets",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "pendingFees",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "haircutBps",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "haircutAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "netAssets",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "positionVersion",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "timestamp",
            "type": "uint64",
            "internalType": "uint64"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "asset",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "bountyBps",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "compound",
    "inputs": [],
    "outputs": [
      {
        "name": "report",
        "type": "tuple",
        "internalType": "struct Types.CompoundReport",
        "components": [
          {
            "name": "profit",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "performanceFee",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "treasuryFee",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "hlxUserMint",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "bountyMint",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "reinvestAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "reinvested",
            "type": "bool",
            "internalType": "bool"
          }
        ]
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "compoundConfig",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct Types.CompoundConfig",
        "components": [
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
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "compoundCooldown",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "deposit",
    "inputs": [
      {
        "name": "assets",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "feeRecipient",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "guardian",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "harvest",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "hlxMintRate",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "hlxToken",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract HLXToken"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "lastCompoundTimestamp",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "minimumProfitThreshold",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "oracleRouter",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "pendingOwner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "performanceFeeBps",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "positionState",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct Types.PositionState",
        "components": [
          {
            "name": "lowerTick",
            "type": "int24",
            "internalType": "int24"
          },
          {
            "name": "upperTick",
            "type": "int24",
            "internalType": "int24"
          },
          {
            "name": "liquidity",
            "type": "uint128",
            "internalType": "uint128"
          },
          {
            "name": "principalAssets",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "version",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "lastRebalance",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "active",
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
    "name": "previewRebalance",
    "inputs": [
      {
        "name": "intent",
        "type": "tuple",
        "internalType": "struct Types.RebalanceIntent",
        "components": [
          {
            "name": "targetLowerTick",
            "type": "int24",
            "internalType": "int24"
          },
          {
            "name": "targetUpperTick",
            "type": "int24",
            "internalType": "int24"
          },
          {
            "name": "targetLiquidity",
            "type": "uint128",
            "internalType": "uint128"
          },
          {
            "name": "assetsToDeploy",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "assetsToWithdraw",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "deadline",
            "type": "uint64",
            "internalType": "uint64"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "quote",
        "type": "tuple",
        "internalType": "struct Types.RebalanceQuote",
        "components": [
          {
            "name": "intentHash",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "positionVersion",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "quotedAt",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "validUntil",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "adapterAssetsBefore",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "assetsToDeploy",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "assetsToWithdraw",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "estimatedLoss",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "expectedAssetsOut",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "expectedAdapterAssetsAfter",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "rebalance",
    "inputs": [
      {
        "name": "intent",
        "type": "tuple",
        "internalType": "struct Types.RebalanceIntent",
        "components": [
          {
            "name": "targetLowerTick",
            "type": "int24",
            "internalType": "int24"
          },
          {
            "name": "targetUpperTick",
            "type": "int24",
            "internalType": "int24"
          },
          {
            "name": "targetLiquidity",
            "type": "uint128",
            "internalType": "uint128"
          },
          {
            "name": "assetsToDeploy",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "assetsToWithdraw",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "deadline",
            "type": "uint64",
            "internalType": "uint64"
          }
        ]
      },
      {
        "name": "quote",
        "type": "tuple",
        "internalType": "struct Types.RebalanceQuote",
        "components": [
          {
            "name": "intentHash",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "positionVersion",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "quotedAt",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "validUntil",
            "type": "uint64",
            "internalType": "uint64"
          },
          {
            "name": "adapterAssetsBefore",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "assetsToDeploy",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "assetsToWithdraw",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "estimatedLoss",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "expectedAssetsOut",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "expectedAdapterAssetsAfter",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      },
      {
        "name": "limits",
        "type": "tuple",
        "internalType": "struct Types.ExecutionLimits",
        "components": [
          {
            "name": "minAssetsOut",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "maxLoss",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "deadline",
            "type": "uint64",
            "internalType": "uint64"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "rebalancePaused",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "rewardDistributor",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "rewardRatioBps",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "setBountyBps",
    "inputs": [
      {
        "name": "newBps",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setCompoundCooldown",
    "inputs": [
      {
        "name": "newCooldown",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setFeeRecipient",
    "inputs": [
      {
        "name": "newFeeRecipient",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setGuardian",
    "inputs": [
      {
        "name": "newGuardian",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setHlxMintRate",
    "inputs": [
      {
        "name": "newRate",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setMinimumProfitThreshold",
    "inputs": [
      {
        "name": "newThreshold",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setPerformanceFeeBps",
    "inputs": [
      {
        "name": "newBps",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setRebalancePaused",
    "inputs": [
      {
        "name": "enabled",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setRewardDistributor",
    "inputs": [
      {
        "name": "newDistributor",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setRewardRatioBps",
    "inputs": [
      {
        "name": "newBps",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setStrategist",
    "inputs": [
      {
        "name": "newStrategist",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "strategist",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "totalAssets",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "totalConservativeAssets",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "totalDeployedAssets",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "totalIdle",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unwindAll",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "vault",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "withdraw",
    "inputs": [
      {
        "name": "assets",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "receiver",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "CompoundCooldownUpdated",
    "inputs": [
      {
        "name": "caller",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "previous",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "newCooldown",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "CompoundExecuted",
    "inputs": [
      {
        "name": "strategy",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "profit",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "performanceFee",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "treasuryFee",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "hlxMinted",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "bounty",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "reinvestAmount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "reinvested",
        "type": "bool",
        "indexed": false,
        "internalType": "bool"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "HlxMintRateUpdated",
    "inputs": [
      {
        "name": "caller",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "previousRate",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "newRate",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferStarted",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "PerformanceFeeUpdated",
    "inputs": [
      {
        "name": "caller",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "previousBps",
        "type": "uint16",
        "indexed": false,
        "internalType": "uint16"
      },
      {
        "name": "newBps",
        "type": "uint16",
        "indexed": false,
        "internalType": "uint16"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RebalancePauseUpdated",
    "inputs": [
      {
        "name": "caller",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "enabled",
        "type": "bool",
        "indexed": false,
        "internalType": "bool"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ReinvestDeferred",
    "inputs": [
      {
        "name": "strategy",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "reason",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RewardRatioUpdated",
    "inputs": [
      {
        "name": "caller",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "previousBps",
        "type": "uint16",
        "indexed": false,
        "internalType": "uint16"
      },
      {
        "name": "newBps",
        "type": "uint16",
        "indexed": false,
        "internalType": "uint16"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StrategyGuardianUpdated",
    "inputs": [
      {
        "name": "guardian",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StrategyRebalanced",
    "inputs": [
      {
        "name": "strategy",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "adapter",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "assetsIn",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "assetsOut",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "lossInAssets",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "adapterAssetsAfter",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "positionVersion",
        "type": "uint64",
        "indexed": false,
        "internalType": "uint64"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StrategyStrategistUpdated",
    "inputs": [
      {
        "name": "strategist",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "CompoundCooldownActive",
    "inputs": [
      {
        "name": "remaining",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "DeadlineExpired",
    "inputs": [
      {
        "name": "currentTimestamp",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "deadline",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "GuardianOnlyOrOwner",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InsufficientLiquidAssets",
    "inputs": [
      {
        "name": "available",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "required",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "InsufficientProfit",
    "inputs": [
      {
        "name": "profit",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "threshold",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "InvalidBountyBps",
    "inputs": [
      {
        "name": "bps",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "InvalidBps",
    "inputs": [
      {
        "name": "bps",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "InvalidHlxMintRate",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidTicks",
    "inputs": [
      {
        "name": "lowerTick",
        "type": "int24",
        "internalType": "int24"
      },
      {
        "name": "upperTick",
        "type": "int24",
        "internalType": "int24"
      }
    ]
  },
  {
    "type": "error",
    "name": "OnlyOwnerCanDisableRebalancePause",
    "inputs": []
  },
  {
    "type": "error",
    "name": "OnlyOwnerOrStrategist",
    "inputs": []
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "QuoteExpired",
    "inputs": [
      {
        "name": "currentTimestamp",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "validUntil",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "QuoteFactsMismatch",
    "inputs": []
  },
  {
    "type": "error",
    "name": "QuoteIntentMismatch",
    "inputs": [
      {
        "name": "expected",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "actual",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ]
  },
  {
    "type": "error",
    "name": "QuoteInvalid",
    "inputs": []
  },
  {
    "type": "error",
    "name": "QuotePositionMismatch",
    "inputs": [
      {
        "name": "expected",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "actual",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "RebalancePaused",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ReentrancyGuardReentrantCall",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SafeERC20FailedOperation",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "StrategyAssetMismatch",
    "inputs": [
      {
        "name": "expected",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "actual",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "Unauthorized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ZeroAddress",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ZeroAmount",
    "inputs": []
  }
] as const;
