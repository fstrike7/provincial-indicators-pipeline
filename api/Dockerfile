# ---- Build stage ----
FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

# Copy wrapper + pom 
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Dependencies
RUN chmod +x ./mvnw
RUN ./mvnw -q -B dependency:go-offline

# Copy n compile
COPY src src
RUN ./mvnw -q -B clean package -DskipTests

# ---- Run stage ----
FROM eclipse-temurin:21-jre
WORKDIR /app
ENV JAVA_OPTS=""
COPY --from=build /workspace/target/*.jar app.jar
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
