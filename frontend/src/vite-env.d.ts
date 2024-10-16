/// <reference types="vite/client" />
interface ImportMetaEnv {
  readonly NODE_ENV: string;
  readonly APP_PORT?: string;
  readonly BACKEND_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
