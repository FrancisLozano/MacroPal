import React from "react";
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
import { loadFont } from "@remotion/fonts";
import interVariable from "@fontsource-variable/inter/files/inter-latin-wght-normal.woff2";

// Variable Inter, so the active label's weight can animate instead of snapping.
const FONT = "Inter Variable";
loadFont({ family: FONT, url: interVariable, weight: "100 900" });

// MacroPal's colors: the app icon's navy and iOS system blue (the app's accent, dark mode).
const NAVY = "#10214D";
const NAVY_DEEP = "#0A1533";
const ACCENT = "#0A84FF";

const STEPS = [
  { label: "LOG FOODS", file: "01-log-foods.png" },
  { label: "CHOOSE FOOD", file: "02-choose-food.png" },
  { label: "FITNESS PROGRESS", file: "03-training-progress.png" },
  { label: "PUSH WORKOUT", file: "04-push-workout.png" },
  { label: "PUSH EXERCISE", file: "05-push-exercises.png" },
];

const FPS = 30;
const STEP_FRAMES = Math.round(3.5 * FPS); // 105
const TRANSITION_FRAMES = 18;
export const TOTAL_FRAMES = STEPS.length * STEP_FRAMES; // 525 = 17.5 s

/**
 * Each step holds, then its last TRANSITION_FRAMES hand over to the next one (the last step
 * hands over to the first). Frame 0 is step 1 fully shown and the final frames finish the
 * hand-over to step 1, so the video loops without a jump.
 */
const useTimeline = () => {
  const frame = useCurrentFrame();
  const current = Math.floor(frame / STEP_FRAMES) % STEPS.length;
  const next = (current + 1) % STEPS.length;
  const t = interpolate(
    frame % STEP_FRAMES,
    [STEP_FRAMES - TRANSITION_FRAMES, STEP_FRAMES],
    [0, 1],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: Easing.inOut(Easing.cubic),
    },
  );
  /** How "active" step i is right now, 0...1. */
  const weight = (i: number) => (i === current ? 1 - t : i === next ? t : 0);
  return { current, next, t, weight };
};

// Phone sized to fit the card: screenshots are 1206 × 2622.
const SCREEN_H = 820;
const SCREEN_W = Math.round((SCREEN_H * 1206) / 2622); // 377
const BEZEL = 14;
const SLIDE_PX = 70;

/** One fixed iPhone frame; only the screen inside it cross-fades and slides. */
const Phone: React.FC = () => {
  const { current, next, t } = useTimeline();
  const layer = (file: string, opacity: number, x: number) => (
    <Img
      src={staticFile(file)}
      style={{
        position: "absolute",
        inset: 0,
        width: "100%",
        height: "100%",
        opacity,
        transform: `translateX(${x}px)`,
      }}
    />
  );
  return (
    <div
      style={{
        width: SCREEN_W + BEZEL * 2,
        height: SCREEN_H + BEZEL * 2,
        borderRadius: 64,
        background: "#0B0B0F",
        padding: BEZEL,
        flexShrink: 0,
        boxShadow:
          "0 0 0 2px #3A3F4B, 0 40px 80px rgba(0, 0, 0, 0.45), 0 12px 24px rgba(0, 0, 0, 0.3)",
      }}
    >
      <div
        style={{
          position: "relative",
          width: SCREEN_W,
          height: SCREEN_H,
          borderRadius: 50,
          overflow: "hidden",
          background: "#000",
        }}
      >
        {layer(STEPS[current].file, 1 - t, -SLIDE_PX * t)}
        {t > 0 && layer(STEPS[next].file, t, SLIDE_PX * (1 - t))}
        {/* Dynamic Island */}
        <div
          style={{
            position: "absolute",
            top: 11,
            left: "50%",
            width: 112,
            height: 32,
            marginLeft: -56,
            borderRadius: 16,
            background: "#000",
          }}
        />
      </div>
    </div>
  );
};

const ROW_H = 112;

const Marker: React.FC<{ row: number; opacity: number }> = ({ row, opacity }) => (
  <div
    style={{
      position: "absolute",
      left: 0,
      top: row * ROW_H + ROW_H / 2 - 16,
      width: 32,
      height: 32,
      borderRadius: 16,
      opacity,
      background: ACCENT,
      boxShadow:
        "0 0 0 8px rgba(10, 132, 255, 0.22), 0 0 32px rgba(10, 132, 255, 0.55)",
    }}
  />
);

const Stepper: React.FC = () => {
  const { current, next, t, weight } = useTimeline();
  const wraps = next < current;

  return (
    <div style={{ position: "relative" }}>
      {/* Track */}
      <div
        style={{
          position: "absolute",
          left: 15,
          top: ROW_H / 2,
          width: 2,
          height: ROW_H * (STEPS.length - 1),
          background: "rgba(255, 255, 255, 0.14)",
        }}
      />
      {/* The marker glides to the next row; on the loop back to step 1 it fades across instead,
          so it never seems to stop on a step in between. */}
      {wraps ? (
        <>
          <Marker row={current} opacity={1 - t} />
          <Marker row={next} opacity={t} />
        </>
      ) : (
        <Marker row={interpolate(t, [0, 1], [current, next])} opacity={1} />
      )}
      {STEPS.map((step, i) => {
        const w = weight(i);
        return (
          <div
            key={step.label}
            style={{
              position: "relative",
              height: ROW_H,
              display: "flex",
              alignItems: "center",
              paddingLeft: 64,
            }}
          >
            {/* Inactive dot */}
            <div
              style={{
                position: "absolute",
                left: 8,
                top: ROW_H / 2 - 8,
                width: 16,
                height: 16,
                borderRadius: 8,
                background: "#2A3A66",
                border: "2px solid rgba(255, 255, 255, 0.25)",
                boxSizing: "border-box",
                opacity: 1 - w,
              }}
            />
            <div
              style={{
                fontSize: 40,
                letterSpacing: 2,
                whiteSpace: "nowrap",
                color: "#FFFFFF",
                fontWeight: interpolate(w, [0, 1], [400, 800]),
                opacity: interpolate(w, [0, 1], [0.38, 1]),
                transform: `translateX(${w * 10}px)`,
              }}
            >
              <span
                style={{
                  color: w > 0.5 ? ACCENT : "#FFFFFF",
                  marginRight: 22,
                  fontVariantNumeric: "tabular-nums",
                }}
              >
                {String(i + 1).padStart(2, "0")}
              </span>
              {step.label}
            </div>
          </div>
        );
      })}
    </div>
  );
};

export const MacroPalTour: React.FC = () => (
  <AbsoluteFill style={{ background: "#060B1A", fontFamily: FONT, padding: 48 }}>
    <div
      style={{
        position: "relative",
        flex: 1,
        borderRadius: 48,
        overflow: "hidden",
        background: `radial-gradient(ellipse 70% 90% at 78% 50%, rgba(10, 132, 255, 0.35), rgba(10, 132, 255, 0) 70%), linear-gradient(135deg, ${NAVY_DEEP} 0%, ${NAVY} 45%, #17418F 100%)`,
        boxShadow: "inset 0 0 0 1px rgba(255, 255, 255, 0.08)",
        display: "flex",
        alignItems: "center",
        padding: "0 160px 0 150px",
      }}
    >
      <div style={{ flex: 1 }}>
        <div
          style={{
            color: "#FFFFFF",
            fontSize: 30,
            fontWeight: 800,
            letterSpacing: 1,
            marginBottom: 6,
          }}
        >
          MacroPal
        </div>
        <div
          style={{
            color: "rgba(255, 255, 255, 0.55)",
            fontSize: 24,
            fontWeight: 400,
            marginBottom: 44,
          }}
        >
          Nutrition and training, in one iOS app
        </div>
        <Stepper />
      </div>
      <Phone />
    </div>
  </AbsoluteFill>
);
