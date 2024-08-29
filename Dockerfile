FROM rocker/rstudio:4.1.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev

# Install R packages
RUN R -e "install.packages(c( \
    'plumber', 'jsonlite', 'ssl', \
    'nlme', 'lme4', 'GLMMadaptive', 'glmmML', 'glmmTMB', 'MCMCglmm', 'brms', \
    'mbest', 'survival', 'CAMAN', 'mclust', 'flexclust', 'aods3', 'censReg', \
    'betareg', 'VGAM', 'gee', 'geepack', 'glmtoolbox', 'mgcv', 'devtools', \
    'remotes', 'testthat', 'covr', 'Formula', 'mathjaxr', 'pander', 'knitr', \
    'rmarkdown', 'tidyverse', 'table1', 'tableone', \
    'meta', 'metafor', 'metasens', 'metadat', 'dmetar', \
    'ggplot2', 'readxl', 'openxlsx' \
))"

# Copy the R script
COPY r_service.R /app/r_service.R

# Set working directory
WORKDIR /app

# Expose port for Plumber API
EXPOSE 10000

# Run the R script
CMD ["R", "-e", "source('r_service.R')"]
