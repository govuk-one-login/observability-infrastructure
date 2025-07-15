FROM node
COPY --from=nbg00813.live.dynatrace.com/linux/oneagent-codemodules:nodejs / /
ENV LD_PRELOAD /opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so

COPY . .

RUN npm ci
RUN npm run build

CMD [ "node", "index.js" ]