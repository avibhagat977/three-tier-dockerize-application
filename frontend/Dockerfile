# Stage 1 (Build Stage)
FROM node:24-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install --legacy-peer-deps

RUN npm list vite > /dev/null 2>&1 || npm install --no-save vite@5.4.11

COPY . .

RUN npm run build

# Stage 2 (Production Stage)
FROM node:24-alpine

WORKDIR /app

COPY --from=build /app/dist ./dist

COPY --from=build /app/node_modules ./node_modules

COPY --from=build /app/vite.preview.config.js ./vite.preview.config.js

EXPOSE 4173

ENTRYPOINT ["node", "--no-warnings"]

CMD ["./node_modules/vite/bin/vite.js", "preview", "--port", "4173", "--host", "--config", "./vite.preview.config.js"]













