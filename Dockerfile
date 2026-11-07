FROM rust:alpine AS builder

RUN apk add --no-cache musl-dev openssl-dev openssl-libs-static pkgconf

# Create base image only with our dependencies and build once
# This creates a cache with the built dependencies
RUN USER=root cargo new --bin idlemail
WORKDIR /idlemail
COPY ./Cargo.toml ./Cargo.lock ./
RUN cargo build --release
RUN rm -rf src

# Add idlemail source-code
COPY . .

RUN cargo clean -p idlemail --release || true
RUN cargo build --release

# Build actual runtime container
FROM alpine:latest
ARG APP=/idlemail

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S idlemail \
    && adduser -S -G idlemail idlemail \
    && mkdir -p ${APP}

COPY --from=builder /idlemail/target/release/idlemail ${APP}/idlemail

RUN chown -R idlemail:idlemail ${APP}

USER idlemail
WORKDIR ${APP}

CMD ["./idlemail", "/idlemail/config.json"]
