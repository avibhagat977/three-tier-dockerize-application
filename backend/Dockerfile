# Stage 1: Build Stage
FROM golang:1.26-alpine AS build

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o devboard-backend ./

# Stage 2: Production Stage
FROM alpine:3.21

WORKDIR /app

RUN apk add --no-cache wget

COPY --from=build /app/devboard-backend ./

EXPOSE 8080

ENTRYPOINT ["./devboard-backend"]
