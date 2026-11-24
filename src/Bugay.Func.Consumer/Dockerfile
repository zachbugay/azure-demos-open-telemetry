FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src

COPY src/Bugay.Func.Consumer/Bugay.Func.Consumer.csproj Bugay.Func.Consumer/
COPY src/Bugay.Func.Contracts/Bugay.Func.Contracts.csproj Bugay.Func.Contracts/
COPY src/Bugay.Data/Bugay.Data.csproj Bugay.Data/
RUN dotnet restore Bugay.Func.Consumer/Bugay.Func.Consumer.csproj

COPY src/Bugay.Func.Consumer/ Bugay.Func.Consumer/
COPY src/Bugay.Func.Contracts/ Bugay.Func.Contracts/
COPY src/Bugay.Data/ Bugay.Data/
RUN dotnet publish Bugay.Func.Consumer/Bugay.Func.Consumer.csproj \
    --configuration Release \
    --output /app \
    --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:11.0
ARG FUNCTIONS_CORE_TOOLS_VERSION=4.16.1

RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl ca-certificates unzip \
    && case "$(dpkg --print-architecture)" in \
        arm64) archive="Azure.Functions.Cli.linux-arm64.${FUNCTIONS_CORE_TOOLS_VERSION}.zip"; checksum="3075a7cfc5dd9cf525d2d3b50e42f1d2727a74bacac7767c8d4471e92f192a6f" ;; \
        amd64) archive="Azure.Functions.Cli.linux-x64.${FUNCTIONS_CORE_TOOLS_VERSION}.zip"; checksum="3fac67f50f3a25dff1dcb40514089726a93cb260d8d6cb064773961af3be16a6" ;; \
        *) echo "Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac \
    && curl --fail --location "https://github.com/Azure/azure-functions-core-tools/releases/download/${FUNCTIONS_CORE_TOOLS_VERSION}/${archive}" --output "/tmp/${archive}" \
    && echo "${checksum}  /tmp/${archive}" | sha256sum --check \
    && unzip "/tmp/${archive}" -d /opt/azure-functions-core-tools \
    && chmod +x /opt/azure-functions-core-tools/func \
    && rm "/tmp/${archive}" \
    && apt-get purge --yes curl unzip \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/site/wwwroot
COPY --from=build /app .

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

ENTRYPOINT ["/opt/azure-functions-core-tools/func"]
CMD ["start", "--port", "80", "--verbose"]
