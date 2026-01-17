FROM golang:1.22-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /observer ./cmd/observer

FROM alpine:3.19
COPY --from=builder /observer /observer
EXPOSE 9100
ENTRYPOINT ["/observer"]
