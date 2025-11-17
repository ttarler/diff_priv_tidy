# Dockerfile for testing tidydp on Linux
# This allows you to test the package in a Ubuntu/Debian environment

FROM rocker/r-ver:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    pandoc \
    qpdf \
    && rm -rf /var/lib/apt/lists/*

# Install R package dependencies
RUN R -e "install.packages(c('devtools', 'testthat', 'knitr', 'rmarkdown', 'magrittr'), repos='https://cloud.r-project.org/')"

# Set working directory
WORKDIR /tidydp

# Copy package files
COPY . /tidydp/

# Build and check the package
RUN R -e "devtools::document()"
RUN R CMD build .
RUN R CMD INSTALL tidydp_*.tar.gz
RUN R CMD check --as-cran tidydp_*.tar.gz

# Run tests
RUN R -e "devtools::test()"

# Default command: open R with the package loaded
CMD ["R"]
