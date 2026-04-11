import type { HTMLAttributes } from 'react';

type SkeletonProps = HTMLAttributes<HTMLDivElement>;

export function Skeleton({ className = '', ...props }: SkeletonProps) {
  return <div className={['animate-pulse rounded-xl bg-[#222936]', className].join(' ')} {...props} />;
}
