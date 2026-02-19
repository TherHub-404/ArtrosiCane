import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {brand} from '../Brand';

export const Background: React.FC = () => {
  const frame = useCurrentFrame();
  const shift = interpolate(frame, [0, 180], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(135deg, ${brand.background} 0%, ${brand.warmPeach} ${50 + shift * 8}%, ${brand.warmOrange} 140%)`,
      }}
    >
      <div
        style={{
          position: 'absolute',
          width: 720,
          height: 720,
          borderRadius: '50%',
          border: `24px solid ${brand.accentBlue}`,
          top: -260,
          right: -120,
          opacity: 0.14,
        }}
      />
      <div
        style={{
          position: 'absolute',
          width: 560,
          height: 560,
          borderRadius: '50%',
          border: `20px solid ${brand.warmOrange}`,
          bottom: -220,
          left: -100,
          opacity: 0.2,
        }}
      />
    </AbsoluteFill>
  );
};
