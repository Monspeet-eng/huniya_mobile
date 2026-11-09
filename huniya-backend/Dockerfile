FROM golang:1.25-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git tzdata

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o huniya-api ./cmd/api/main.go

FROM alpine:3.20

WORKDIR /app
RUN apk add --no-cache ca-certificates tzdata && mkdir -p /app/uploads

COPY --from=builder /app/huniya-api .
COPY --from=builder /app/.env.example ./.env
COPY --from=builder /app/docs ./docs

EXPOSE 8080

CMD ["./huniya-api"]
