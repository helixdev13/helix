'use client';

import { useEffect, useState } from 'react';

import { ConnectWalletButton } from '@/components/ConnectWalletButton';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';

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
      <div className="mx-auto flex max-w-[1000px] flex-col items-stretch gap-3 px-4 py-4 sm:px-6 lg:flex-row lg:items-center lg:justify-between">
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
          className="w-full lg:max-w-xs lg:self-center"
        >
          <TabsList className="w-full justify-center">
            <TabsTrigger value="vaults">Vaults</TabsTrigger>
            <TabsTrigger value="compound">Compound</TabsTrigger>
          </TabsList>
        </Tabs>

        <div className="w-full self-stretch lg:w-auto lg:self-end">
          <ConnectWalletButton className="w-full min-w-0 lg:min-w-[170px]" />
        </div>
      </div>
    </header>
  );
}
