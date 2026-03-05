# Stage 1: Builder Flutter
FROM cirrusci/flutter:latest as builder

WORKDIR /app

# Configuration Flutter
RUN flutter config --no-analytics
RUN flutter config --enable-web

# Copier les fichiers pubspec
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copier le code source
COPY . .

# Build Web Release
RUN flutter build web --release --no-tree-shake-icons

---

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Metadata
LABEL maintainer="votre_email@example.com"
LABEL description="Flutter Web App"

# Copier les fichiers buildés
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copier la configuration Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/index.html || exit 1

# Expose port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]