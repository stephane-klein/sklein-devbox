FROM node:24-slim

RUN npm install -g pnpm@11.2.2

WORKDIR /app/

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY src/ ./src/
COPY sqls/ ./sqls/
COPY entrypoint.sh /entrypoint.sh

ENV POSTGRES_HOST=postgres
ENV NODE_ENV=production

ENTRYPOINT ["/entrypoint.sh"]
CMD ["hello"]