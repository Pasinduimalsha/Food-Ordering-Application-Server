# Stage 1: Build stage (Using JDK + Maven Wrapper)
FROM eclipse-temurin:17-jdk-focal AS builder
WORKDIR /app

# Copy Maven Wrapper and pom.xml first to cache dependencies
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source and build the application
COPY src ./src
RUN ./mvnw clean package -DskipTests

# Stage 2: Runtime stage (Lightweight JRE)
FROM eclipse-temurin:17-jre-focal AS runtime
WORKDIR /app

# Create a non-root user (Ubuntu syntax)
RUN groupadd -r spring && useradd -r -g spring spring
USER spring

# Copy the built JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Application configuration
ENV PORT=8081
EXPOSE 8080

# Healthcheck to monitor the app's health
# HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
#   CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
