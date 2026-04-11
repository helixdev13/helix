import type { HTMLAttributes } from 'react';

type SkeletonProps = HTMLAttributes<HTMLDivElement>;

export function Skeleton({ className = '', ...props }: SkeletonProps) {
  return <div className={['animate-pulse rounded-xl bg-[#F0E8E8]', className].join(' ')} {...props} />;
}
