# syntax=docker/dockerfile:1
#
# Contoso Orders – container image.
#
# Two stages. The first has Maven and a full JDK and produces the jar. The second
# is a small image with only a Java runtime, and that is what we ship. Nothing from
# the build stage (Maven, sources, the ~50 MB of downloaded dependencies) ends up in
# the final image.

# ---------- Stage 1: build ---------------------------------------------------
# A pinned image that already contains Maven 3.9 and a Java 21 JDK.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Copy only the pom first and download the dependencies. Docker caches each step
# as a layer, so as long as pom.xml does not change this (slow) step is skipped on
# the next build, even when the Java sources changed.
COPY pom.xml .
RUN mvn -B -q --no-transfer-progress dependency:go-offline

# Now the sources. Tests are NOT run here: CI already ran them on this exact commit
# before the image is built. Building the image is packaging, not verification.
COPY src ./src
RUN mvn -B -q --no-transfer-progress package -DskipTests \
    && mv target/contoso-orders-*.jar target/app.jar

# ---------- Stage 2: runtime -------------------------------------------------
# Only a Java 21 runtime (no compiler, no Maven), on Alpine Linux. About 1/4 the
# size of the build image.
FROM eclipse-temurin:21-jre-alpine AS runtime

# Never run as root inside the container. If the app is compromised, the attacker
# gets an unprivileged user, not root on the container.
RUN addgroup -S app && adduser -S -G app -h /app app
WORKDIR /app
USER app

# The jar from stage 1, owned by the unprivileged user.
COPY --from=build --chown=app:app /build/target/app.jar /app/app.jar

# Documentation for humans and tooling: the app listens on 8080.
EXPOSE 8080

# Docker itself checks the app every 30 s by calling the health endpoint. If it
# fails three times in a row the container is marked "unhealthy", which an
# orchestrator (Compose, Kubernetes, AKS) uses to restart or stop routing to it.
# Alpine's wget is built in, so no extra packages are needed.
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD wget -qO- http://localhost:8080/orders/health | grep -q '"UP"' || exit 1

# Extra JVM flags can be passed at run time with -e JAVA_OPTS="...". Memory limits
# set on the container are honoured automatically by Java 21.
ENV JAVA_OPTS=""

# exec replaces the shell with the java process so it receives SIGTERM directly
# and can shut down cleanly when the container is stopped.
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
