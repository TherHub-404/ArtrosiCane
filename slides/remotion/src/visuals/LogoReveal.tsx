import React from 'react';
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {layout} from '../Brand';
import {Background} from './Background';

export const LogoReveal: React.FC<{title?: string; subtitle?: string}> = ({
  title = 'Gestione artrosi canina',
  subtitle = 'Approccio clinico + routine quotidiana',
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const reveal = spring({
    fps,
    frame,
    config: {damping: 200},
    durationInFrames: 36,
  });

  const logoScale = interpolate(reveal, [0, 1], [0.9, 1]);
  const logoOpacity = interpolate(frame, [0, 18], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const copyOpacity = interpolate(frame, [14, 36], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const copyY = interpolate(frame, [14, 36], [26, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      <Background />
      <AbsoluteFill
        style={{
          justifyContent: 'center',
          alignItems: 'center',
          padding: `${layout.safeY}px ${layout.safeX}px`,
        }}
      >
        <Img
          src={staticFile('ArtrosiCane-Logo.png')}
          style={{
            width: 760,
            maxWidth: '88%',
            transform: `scale(${logoScale})`,
            opacity: logoOpacity,
          }}
        />

        <div
          style={{
            marginTop: 36,
            textAlign: 'center',
            opacity: copyOpacity,
            transform: `translateY(${copyY}px)`,
            fontFamily: 'Montserrat, Avenir, Helvetica, Arial, sans-serif',
          }}
        >
          <div style={{fontSize: 56, fontWeight: 800, letterSpacing: -1, color: '#1E2D62'}}>
            {title}
          </div>
          <div style={{fontSize: 34, fontWeight: 500, marginTop: 14, color: '#24568E'}}>
            {subtitle}
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
