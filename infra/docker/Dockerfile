# Placeholder multi-stage build for an optional leaderboards/cloud-save backend.
# This repository ships no backend source code yet — replace `backend/` with your
# actual service (e.g. a small Ktor, Ktor+Exposed, or Node/Express API) before
# building this image. Delete infra/docker/ entirely if your game is offline-only.

FROM eclipse-temurin:22-jdk-jammy AS build
WORKDIR /src
# COPY backend/ .
# RUN ./gradlew installDist

FROM eclipse-temurin:22-jre-jammy AS runtime
WORKDIR /app
RUN useradd -m -s /bin/bash appuser
USER appuser
# COPY --from=build /src/build/install/backend /app
EXPOSE 8080
COPY infra/docker/entrypoint.sh /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
# CMD ["/app/bin/backend"]
