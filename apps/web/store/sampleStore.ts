import { create } from "zustand";

type SampleState = {
  count: number;
  label: string;
  setLabel: (label: string) => void;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
};

const useSampleStore = create<SampleState>((set) => ({
  count: 0,
  label: "Clicks",
  setLabel: (label) => set({ label }),
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));

export default useSampleStore;
