# Dockerfile

# --- Build Stage ---
# Use a Go-alpine image for building the application
FROM golang:1.21-alpine AS builder

# Install git, which is needed to clone the repository
RUN apk add --no-cache git

# Set the working directory
WORKDIR /app

# Clone the repository from GitHub
# If you are using your own fork, you can change the URL here
RUN git clone https://github.com/MS-Jahan/email-verifier.git .

# Download Go module dependencies
RUN go mod download

# Build the Go application
# This creates a static binary which is ideal for minimal container images
# The main package for the API server is located in cmd/apiserver
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /app/server ./cmd/apiserver

# --- Final Stage ---
# Use a minimal alpine image for the final container
FROM alpine:latest

# It's a good practice to run applications as a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the built binary from the builder stage
COPY --from=builder /app/server /app/server

# The application uses data files for disposable domains, free domains, etc.
# These need to be included in the final image.
COPY --from=builder /app/data /app/data

# Switch to the non-root user
USER appuser

# Expose port 8080.
# I am assuming the application listens on port 8080, which is a common default.
# If the application uses a different port, you will need to change this value.
EXPOSE 8080

# Set the entrypoint for the container to run the application
ENTRYPOINT ["/app/server"]
