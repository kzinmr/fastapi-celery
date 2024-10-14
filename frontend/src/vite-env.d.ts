/// <reference types="vite/client" />
interface ImportMetaEnv {
  readonly NODE_ENV: string;
  readonly APP_PORT?: string;
  readonly SERVER_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
