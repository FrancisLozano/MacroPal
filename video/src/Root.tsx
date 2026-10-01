import React from "react";
import { Composition } from "remotion";
import { MacroPalTour, TOTAL_FRAMES } from "./MacroPalTour";

export const Root: React.FC = () => (
  <Composition
    id="MacroPalTour"
    component={MacroPalTour}
    durationInFrames={TOTAL_FRAMES}
    fps={30}
    width={1920}
    height={1080}
  />
);
