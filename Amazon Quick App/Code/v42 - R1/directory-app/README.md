# Directory App

A personal/church directory application built with React + TypeScript + Vite.

## Getting Started

```bash
npm install
npm run dev
```

## Building

```bash
npm run build
```

## Notes

- This export is a standalone version. The original app uses `@amzn/quick-pages-runtime-lib`
  for persistent storage (App Storage APIs). In this standalone version, you'll need to
  replace those calls with your own storage backend (e.g. localStorage, a REST API, etc.).
- Search for `putSharedItem`, `getSharedItem`, `listSharedItems`, `deleteSharedItem`
  in `src/storage.ts` to see where storage calls are made.
- The `downloadFile` import would also need to be replaced with standard browser download logic.

