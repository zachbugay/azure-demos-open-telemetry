FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src

COPY src/Bugay.Data.Generator/Bugay.Data.Generator.csproj Bugay.Data.Generator/
COPY src/Bugay.Func.Contracts/Bugay.Func.Contracts.csproj Bugay.Func.Contracts/
RUN dotnet restore Bugay.Data.Generator/Bugay.Data.Generator.csproj

COPY src/Bugay.Data.Generator/ Bugay.Data.Generator/
COPY src/Bugay.Func.Contracts/ Bugay.Func.Contracts/
RUN dotnet publish Bugay.Data.Generator/Bugay.Data.Generator.csproj \
    --configuration Release \
    --output /app \
    --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:11.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Bugay.Data.Generator.dll"]
