FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src

COPY src/Bugay.Database/Bugay.Database.csproj Bugay.Database/
RUN dotnet restore Bugay.Database/Bugay.Database.csproj

COPY src/Bugay.Database/ Bugay.Database/
RUN dotnet publish Bugay.Database/Bugay.Database.csproj \
    --configuration Release \
    --output /app \
    --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:11.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Bugay.Database.dll"]
