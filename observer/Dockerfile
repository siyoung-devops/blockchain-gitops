# 1. Go 빌드용 이미지
From golang:1.22-alpine AS builder

# 2. 컨테이너 내부 작업 디렉토리 생성
WORKDIR /app

# 3. go.mod, go.sum 복사
COPY go.mod go.sum ./
# 4. 의존성 다운로드
RUN go mod download

# 5. 전체 코드 복사
COPY . .
# 6. 바이너리 빌드 - C 라이브러리 사용 안함, Linux OS, AMD64 아키텍처 타겟
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o observer

# 7. 실행 전용 최소 이미지
FROM alpine:3.19
WORKDIR /app
# 8. 빌드된 바이너리만 복사
COPY --from=builder /app/observer .
# 9. 컨테이너 시작 시 실행
CMD ["./observer"]