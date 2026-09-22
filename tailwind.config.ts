import type { Config } from "tailwindcss";
export default { content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"], theme: { extend: { colors: { navy: "#10283f", ocean: "#127c88", foam: "#edf7f5", coral: "#ed744f" } } }, plugins: [] } satisfies Config;
