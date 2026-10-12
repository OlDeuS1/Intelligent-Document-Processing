FROM node:20-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      poppler-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY ocr-service/ ./ocr-service/

EXPOSE 3001

CMD ["node", "ocr-service/ocr-server.js"]
