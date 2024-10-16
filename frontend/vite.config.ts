import { defineConfig, UserConfig } from "vite";
import react from "@vitejs/plugin-react-swc";

// https://vitejs.dev/config/
export default defineConfig((): UserConfig => {
  const isDevelopment = process.env.NODE_ENV === "development";
  const port = process.env.APP_PORT ? parseInt(process.env.APP_PORT, 10) : 5174;
  const serverUrl = process.env.BACKEND_URL ?? "http://localhost:5175";

  return {
    plugins: [react()],
    server: {
      host: "0.0.0.0",
      port,
      strictPort: false,
      proxy: isDevelopment
        ? {
            "/api/": {
              target: serverUrl,
              changeOrigin: true,
            },
          }
        : undefined,
    },
  };
});
