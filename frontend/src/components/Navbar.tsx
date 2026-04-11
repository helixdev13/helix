'use client';

import { useEffect, useState } from 'react';

import { ConnectButton } from '@rainbow-me/rainbowkit';

import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { GradientButton } from '@/components/GradientButton';

type DashboardTab = 'vaults' | 'compound';

function tabFromHash(hash: string): DashboardTab {
  return hash.replace('#', '') === 'compound' ? 'compound' : 'vaults';
}

export function Navbar() {
  const [activeTab, setActiveTab] = useState<DashboardTab>('vaults');

  useEffect(() => {
    const syncFromHash = () => setActiveTab(tabFromHash(window.location.hash));
    syncFromHash();
    window.addEventListener('hashchange', syncFromHash);
    return () => window.removeEventListener('hashchange', syncFromHash);
  }, []);

  const changeTab = (tab: string) => {
    const nextTab = tabFromHash(`#${tab}`);
    if (typeof window !== 'undefined') {
      window.location.hash = nextTab;
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
    setActiveTab(nextTab);
  };

  return (
    <header className="sticky top-0 z-50 border-b border-[#F3DDE3] bg-white/95 backdrop-blur">
      <div className="mx-auto flex max-w-[1000px] flex-col gap-4 px-4 py-4 sm:px-6 lg:flex-row lg:items-center lg:justify-between">
        <button
          type="button"
          onClick={() => changeTab('vaults')}
          className="self-start text-2xl font-semibold tracking-tight bg-[linear-gradient(135deg,#E8A0B8,#D4797F)] bg-clip-text text-transparent"
        >
          Helix
        </button>

        <Tabs
          defaultValue={activeTab}
          value={activeTab}
          onValueChange={changeTab}
          className="w-full max-w-xs self-center"
        >
          <TabsList className="w-full justify-center">
            <TabsTrigger value="vaults">Vaults</TabsTrigger>
            <TabsTrigger value="compound">Compound</TabsTrigger>
          </TabsList>
        </Tabs>

        <div className="self-end">
          <ConnectButton.Custom>
            {({ account, chain, mounted, openAccountModal, openChainModal, openConnectModal }) => {
              if (!mounted) {
                return (
                  <GradientButton className="min-w-[170px]" disabled>
                    Connect Wallet
                  </GradientButton>
                );
              }

              const connected = Boolean(account && chain);
              const label = !connected
                ? 'Connect Wallet'
                : chain?.unsupported
                  ? 'Switch to Citrea'
                  : 'Open Wallet';

              return (
                <GradientButton
                  className="min-w-[170px]"
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
                >
                  {label}
                </GradientButton>
              );
            }}
          </ConnectButton.Custom>
        </div>
      </div>
    </header>
  );
}
