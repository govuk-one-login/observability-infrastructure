FROM node

COPY . .

RUN npm ci
RUN npm run build

CMD [ "node", "index.js" ]