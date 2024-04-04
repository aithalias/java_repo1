FROM maven:amazoncorretto as build
WORKDIR /javaapps
COPY . .
RUN mvn clean install

FROM adhig93/tomcat-conf
COPY --from=build /javaapps/target/*.war /usr/local/tomcat/webapps/
