import React from 'react';
import {Composition} from 'remotion';
import {TransitionSeries, linearTiming} from '@remotion/transitions';
import {fade} from '@remotion/transitions/fade';
import {FeatureStrip} from './visuals/FeatureStrip';
import {LogoReveal} from './visuals/LogoReveal';
import {OutcomeScene} from './visuals/OutcomeScene';
import {OnboardingFlowGif} from './visuals/OnboardingFlowGif';
import {IPhone17MockupGif} from './visuals/IPhone17MockupGif';
import {EndToEndJourneyGif} from './visuals/EndToEndJourneyGif';

const fps = 30;

const Showcase: React.FC = () => {
  return (
    <TransitionSeries>
      <TransitionSeries.Sequence durationInFrames={90}>
        <LogoReveal />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={linearTiming({durationInFrames: 16})} />

      <TransitionSeries.Sequence durationInFrames={110}>
        <FeatureStrip />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={linearTiming({durationInFrames: 16})} />

      <TransitionSeries.Sequence durationInFrames={90}>
        <OutcomeScene />
      </TransitionSeries.Sequence>
    </TransitionSeries>
  );
};

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="ArtrosiSlidesShowcase"
        component={Showcase}
        width={1920}
        height={1080}
        fps={fps}
        durationInFrames={258}
      />

      <Composition
        id="ArtrosiLogoReveal"
        component={LogoReveal}
        width={1920}
        height={1080}
        fps={fps}
        durationInFrames={90}
        defaultProps={{
          title: 'ArtrosiCane',
          subtitle: 'Digital companion per mobilita e benessere',
        }}
      />

      <Composition
        id="ArtrosiOnboardingFlowGif"
        component={OnboardingFlowGif}
        width={1920}
        height={1080}
        fps={fps}
        durationInFrames={180}
      />

      <Composition
        id="ArtrosiIPhone17MockupGif"
        component={IPhone17MockupGif}
        width={1080}
        height={1920}
        fps={fps}
        durationInFrames={180}
      />

      <Composition
        id="ArtrosiEndToEndJourneyGif"
        component={EndToEndJourneyGif}
        width={1080}
        height={1920}
        fps={fps}
        durationInFrames={220}
      />
    </>
  );
};
