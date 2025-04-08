# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY . .
RUN yarn install --frozen-lockfile && yarn build

# Stage 2: Run
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000
ENV PORT=3000
CMD ["yarn", "start"]
