# Vercel deployment

This version is configured for Vercel serverless deployment.

- `server.js` is CommonJS and exports the Express app.
- The server does not call `app.listen()` on Vercel.
- Web assets are under `public/` and served by Express.
- `vercel.json` routes requests to the serverless function.

Deploy by pushing the contents of this folder to the GitHub repository and redeploying the Vercel project.
