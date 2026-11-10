FROM node:24-alpine
ENV NODE_ENV=production HOST=0.0.0.0 PORT=8787 USAGE_FILE=/data/usage.json
WORKDIR /app
COPY --chown=node:node server/*.mjs ./server/
RUN mkdir /data && chown node:node /data
USER node
EXPOSE 8787
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8787)+'/healthz').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"
CMD ["node", "server/server.mjs"]
