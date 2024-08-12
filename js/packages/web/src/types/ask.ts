type DeltaError = {
  type: "error";
  reason: string;
};

type DeltaProgress = {
  type: "progress";
  content: string;
};

type DeltaComplete = {
  type: "complete";
};

export type AskReference = {
  url: string;
  title: string;
};

export type Delta = DeltaError | DeltaProgress | DeltaComplete;

type UUID_V4 = ReturnType<typeof crypto.randomUUID>;

export type AskFunction = (
  id: UUID_V4,
  query: string,
  handleDelta: (delta: Delta) => void,
  signal?: AbortSignal,
) => Promise<null>;
