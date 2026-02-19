import React from 'react';
import {AbsoluteFill, Img, Sequence, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {brand} from '../Brand';
import {OnboardingFlowGif} from './OnboardingFlowGif';
import {IPhone17MockupGif} from './IPhone17MockupGif';

export const EndToEndJourneyGif: React.FC = () => {
  const frame = useCurrentFrame();

  const overlay = interpolate(frame, [0, 20, 120, 140], [1, 0, 0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      <Sequence from={0} durationInFrames={100}>
        <OnboardingFlowGif />
      </Sequence>
      <Sequence from={100} durationInFrames={120}>
        <IPhone17MockupGif />
      </Sequence>

      <AbsoluteFill
        style={{
          backgroundColor: '#FFFFFF',
          opacity: overlay,
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <Img src={staticFile('ArtrosiCane-Logo.png')} style={{width: 420}} />
        <div
          style={{
            marginTop: 28,
            fontFamily: 'Montserrat, sans-serif',
            fontWeight: 900,
            fontSize: 52,
            color: brand.primaryBlue,
          }}
        >
          Jotform {'->'} Supabase {'->'} App
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
