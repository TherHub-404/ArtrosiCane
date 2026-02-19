import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {brand, layout} from '../Brand';
import {Background} from './Background';

export const OutcomeScene: React.FC = () => {
  const frame = useCurrentFrame();

  const headlineOpacity = interpolate(frame, [0, 24], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const ringScale = interpolate(frame, [6, 46], [0.8, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      <Background />
      <AbsoluteFill
        style={{
          padding: `${layout.safeY}px ${layout.safeX}px`,
          fontFamily: 'Montserrat, Avenir, Helvetica, Arial, sans-serif',
          justifyContent: 'center',
        }}
      >
        <div style={{display: 'flex', alignItems: 'center', gap: 56}}>
          <div
            style={{
              width: 420,
              height: 420,
              borderRadius: '50%',
              border: `26px solid ${brand.warmOrange}`,
              borderRightColor: 'transparent',
              transform: `scale(${ringScale})`,
              opacity: 0.9,
              position: 'relative',
            }}
          >
            <div
              style={{
                position: 'absolute',
                width: 280,
                height: 280,
                borderRadius: '50%',
                border: `22px solid ${brand.accentBlue}`,
                borderLeftColor: 'transparent',
                top: 64,
                left: 112,
              }}
            />
          </div>

          <div style={{maxWidth: 1150, opacity: headlineOpacity}}>
            <div style={{fontSize: 72, lineHeight: 1.05, fontWeight: 800, color: brand.primaryBlue}}>
              Visual narrative per presentazioni mediche e investor deck
            </div>
            <div style={{fontSize: 34, lineHeight: 1.3, marginTop: 22, color: '#1F4D83'}}>
              Storyline chiara: problema, valutazione, piano quotidiano, outcome.
            </div>
            <div style={{fontSize: 29, lineHeight: 1.3, marginTop: 16, color: '#2E3E67'}}>
              Pronta per PowerPoint, Keynote o video social verticali.
            </div>
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
