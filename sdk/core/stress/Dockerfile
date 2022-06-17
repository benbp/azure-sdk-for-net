FROM mcr.microsoft.com/dotnet/sdk:6.0-cbl-mariner1.0

# Copy in engineering system needed to build
COPY ./eng/ /app/eng/
COPY ./tools/ /app/tools/
COPY ./*.proj /app/
COPY ./Directory.Build.props/ /app/
COPY ./Directory.Build.targets/ /app/
COPY ./NuGet.Config/ /app/

# Copy in Core Source Code
COPY ./sdk/core/ /app/sdk/core/
