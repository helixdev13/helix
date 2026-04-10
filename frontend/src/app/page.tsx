'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useBalance } from 'wagmi';

import { citrea } from '../config/chains';
import { Button } from '../components/ui/button';

function StatRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left">
      <div className="text-[11px] uppercase tracking-[0.2em] text-slate-400">{label}</div>
      <div className="mt-1 break-all text-sm font-medium text-white">{value}</div>
    </div>
  );
}

export default function Home() {
  const { address, chain, isConnected } = useAccount();
  const { data: balance, isLoading } = useBalance({
    address,
    chainId: citrea.id,
    query: {
      enabled: Boolean(address),
    },
  });

  const balanceText = isLoading
    ? 'Loading balance...'
    : balance
      ? `${balance.formatted} ${balance.symbol}`
      : '0 cBTC';

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(34,197,94,0.12),_transparent_28%),linear-gradient(180deg,_#020617_0%,_#0f172a_52%,_#111827_100%)] text-slate-100">
      <div className="mx-auto flex min-h-screen w-full max-w-5xl items-center justify-center px-6 py-16">
        <div className="w-full max-w-2xl rounded-[2rem] border border-white/10 bg-white/5 p-8 shadow-2xl backdrop-blur-xl sm:p-10">
          <div className="space-y-3 text-center">
            <p className="text-xs uppercase tracking-[0.35em] text-emerald-300">Citrea mainnet</p>
            <h1 className="text-4xl font-semibold tracking-tight text-white sm:text-5xl">
              Helix — Citrea Yield Optimizer
            </h1>
            <p className="mx-auto max-w-xl text-base leading-7 text-slate-300 sm:text-lg">
              Deposit USDC.e, earn trading fees + HLX rewards
            </p>
          </div>

          <div className="mt-8 flex justify-center">
            <ConnectButton.Custom>
              {({ account, chain, openAccountModal, openChainModal, openConnectModal, mounted }) => {
                const connected = Boolean(mounted && account && chain);
                const primaryLabel = !connected
                  ? 'Connect wallet'
                  : chain?.unsupported
                    ? 'Switch to Citrea'
                    : 'Open account';

                return (
                  <Button
                    type="button"
                    onClick={() => {
                      if (!connected) {
                        openConnectModal();
                        return;
                      }

                      if (chain?.unsupported) {
                        openChainModal();
                        return;
                      }

                      openAccountModal();
                    }}
                    className="min-w-[180px]"
                  >
                    {primaryLabel}
                  </Button>
                );
              }}
            </ConnectButton.Custom>
          </div>

          {isConnected && address && (
            <div className="mt-8 grid gap-3 sm:grid-cols-3">
              <StatRow label="Wallet address" value={address} />
              <StatRow label="Network" value={chain?.name ?? citrea.name} />
              <StatRow label="cBTC balance" value={balanceText} />
            </div>
          )}

          <div className="mt-8 rounded-2xl border border-emerald-400/20 bg-emerald-400/5 px-4 py-3 text-sm text-emerald-100/90">
            Frontend scaffolding only. No vault ABIs or product-specific actions are wired yet.
          </div>
        </div>
      </div>
    </main>
  );
}
