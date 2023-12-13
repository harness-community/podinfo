# FROM golang:1.21-alpine as builder

# RUN mkdir -p /podinfo/

# WORKDIR /podinfo

# COPY . .

# RUN go mod download


# ARG REVISION
# RUN CGO_ENABLED=0 go build -ldflags "-s -w \
#     -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}" \
#     -a -o bin/podinfo cmd/podinfo/*

# RUN CGO_ENABLED=0 go build -ldflags "-s -w \
#     -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}" \
#     -a -o bin/podcli cmd/podcli/*

# FROM alpine:3.18

# ARG BUILD_DATE
# ARG VERSION
# ARG REVISION

# LABEL maintainer="stefanprodan"

# RUN addgroup -S app \
#     && adduser -S -G app app \
#     && apk --no-cache add \
#     ca-certificates curl netcat-openbsd

# WORKDIR /home/app

# COPY --from=builder /podinfo/bin/podinfo .
# COPY --from=builder /podinfo/bin/podcli /usr/local/bin/podcli
# COPY ./ui ./ui
# RUN chown -R app:app ./

# USER app

# CMD ["./podinfo"]


# Use a specific version of the golang image
FROM golang:1.21-alpine as builder

# Create the working directory in one step
WORKDIR /podinfo

# Copy the Go module files first and download dependencies. This leverages Docker's cache to prevent re-downloading dependencies if the go.mod and go.sum files haven't changed.
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the binaries in one step to reduce layers. Also, remove the second build command if it's not necessary.
ARG REVISION
RUN CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}" -a -o bin/podinfo cmd/podinfo/*

# Use a specific version of the alpine image
FROM alpine:3.18

# Set labels in one layer
LABEL maintainer="stefanprodan"

# Add the user and group in one command, and only add the ca-certificates package if it's necessary for your application.
RUN addgroup -S app && adduser -S -G app app && apk --no-cache add ca-certificates

# Set the working directory
WORKDIR /home/app

# Copy the necessary files from the builder stage
COPY --from=builder /podinfo/bin/podinfo .
COPY --from=builder /podinfo/ui ./ui

# Set the correct permissions
RUN chown -R app:app ./

# Use the non-root user
USER app

# Set the default command to run the application
CMD ["./podinfo"]
