# Testing tidydp on Linux Systems

This document provides instructions for testing the tidydp package on Linux systems to ensure cross-platform compatibility.

## Automated Testing with GitHub Actions

The package includes a GitHub Actions workflow that automatically tests the package on:

- **Ubuntu Linux** (latest, R-devel, R-release, R-oldrel-1)
- **macOS** (latest, R-release)
- **Windows** (latest, R-release)

To enable automated testing:

1. Push your code to GitHub
2. The workflow in `.github/workflows/R-CMD-check.yaml` will run automatically
3. View results in the "Actions" tab of your GitHub repository

## Manual Testing with Docker

### Prerequisites

Install Docker on your system:
- **Ubuntu/Debian**: `sudo apt-get install docker.io`
- **Fedora/RHEL**: `sudo dnf install docker`
- **macOS**: [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)

### Build and Test

1. **Build the Docker image** (from the package root directory):
   ```bash
   docker build -t tidydp-test .
   ```

2. **Run the container** to execute tests:
   ```bash
   docker run --rm tidydp-test
   ```

3. **Interactive testing**:
   ```bash
   docker run -it --rm tidydp-test R
   ```

   Then in R:
   ```r
   library(tidydp)

   # Run examples
   example(dp_add_noise)
   example(dp_count)

   # Run tests
   devtools::test()

   # Build vignette
   browseVignettes("tidydp")
   ```

### Test on Specific Linux Distributions

#### Ubuntu 22.04 (Jammy)
```bash
docker run -it --rm -v $(pwd):/tidydp -w /tidydp rocker/r-ver:4.5.2 bash
# Inside container:
apt-get update && apt-get install -y libcurl4-openssl-dev libssl-dev pandoc
R -e "install.packages(c('devtools', 'magrittr', 'testthat', 'knitr', 'rmarkdown'))"
R CMD build .
R CMD check --as-cran tidydp_*.tar.gz
```

#### Debian (Stable)
```bash
docker run -it --rm -v $(pwd):/tidydp -w /tidydp rocker/r-ver:4.5.2 bash
# Same commands as Ubuntu
```

#### Fedora
```bash
docker run -it --rm -v $(pwd):/tidydp -w /tidydp fedora:latest bash
# Inside container:
dnf install -y R pandoc qpdf
cd /tidydp
R -e "install.packages(c('devtools', 'magrittr', 'testthat', 'knitr', 'rmarkdown'))"
R CMD build .
R CMD check --as-cran tidydp_*.tar.gz
```

## Testing on Native Linux Systems

If you have access to a Linux system:

### Install R and Dependencies

#### Ubuntu/Debian
```bash
# Add CRAN repository
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+

# Install R and dependencies
sudo apt-get install -y \
  r-base \
  r-base-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  pandoc \
  qpdf
```

#### Fedora/RHEL/CentOS
```bash
sudo dnf install -y R pandoc qpdf libcurl-devel openssl-devel
```

### Install and Test the Package

```bash
# Clone or copy the package
cd /path/to/tidydp

# Start R
R

# In R:
install.packages(c('devtools', 'magrittr', 'testthat', 'knitr', 'rmarkdown'))
devtools::install()
devtools::check()
devtools::test()

# Test loading and basic functionality
library(tidydp)
data <- data.frame(x = 1:10, y = rnorm(10))
result <- data %>% dp_add_noise("y", epsilon = 0.5, lower = c(y = -5), upper = c(y = 5))
print(result)
```

## Continuous Integration Setup

### GitHub Actions (Recommended)

The included `.github/workflows/R-CMD-check.yaml` file provides:

- Multi-platform testing (Linux, macOS, Windows)
- Multiple R versions (devel, release, oldrel-1)
- Automatic checks on push and pull requests
- CRAN-style package checking

To use:
1. Push your repository to GitHub
2. Enable GitHub Actions in repository settings
3. Workflow runs automatically on commits

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
test:
  image: rocker/r-ver:latest
  before_script:
    - apt-get update && apt-get install -y libcurl4-openssl-dev libssl-dev pandoc qpdf
    - R -e "install.packages(c('devtools', 'testthat', 'knitr', 'rmarkdown', 'magrittr'))"
  script:
    - R CMD build .
    - R CMD check --as-cran tidydp_*.tar.gz
    - R -e "devtools::test()"
```

## Known Platform-Specific Considerations

### Linux Compatibility

✅ **The tidydp package is fully compatible with Linux** because:

1. **Pure R Implementation**: No compiled code (C/C++/Fortran)
2. **Standard Dependencies**: Only uses base R packages and CRAN packages
3. **No System Calls**: No platform-specific system() calls
4. **No Hardcoded Paths**: All paths are relative or use R's path functions
5. **Cross-Platform Tests**: All tests work on Linux, macOS, and Windows

### Dependency Availability on Linux

All dependencies are available on Linux through CRAN:

| Package    | Linux Status | Notes |
|------------|--------------|-------|
| magrittr   | ✅ Available | Pure R package |
| stats      | ✅ Built-in  | Base R package |
| testthat   | ✅ Available | Pure R package |
| knitr      | ✅ Available | Pure R package |
| rmarkdown  | ✅ Available | Requires pandoc (usually pre-installed) |

### System Requirements

**Minimal requirements:**
- R >= 4.0.0
- Standard Linux distribution (Ubuntu, Debian, Fedora, RHEL, etc.)

**Optional (for vignettes):**
- pandoc (usually included with R or rmarkdown)
- qpdf (for PDF compression, not required)

## Troubleshooting

### Issue: Missing system libraries

**Symptom**: Installation fails with "cannot find -lcurl" or similar

**Solution**:
```bash
# Ubuntu/Debian
sudo apt-get install libcurl4-openssl-dev libssl-dev

# Fedora/RHEL
sudo dnf install libcurl-devel openssl-devel
```

### Issue: Pandoc not found

**Symptom**: Vignette building fails

**Solution**:
```bash
# Ubuntu/Debian
sudo apt-get install pandoc

# Fedora/RHEL
sudo dnf install pandoc
```

### Issue: qpdf warning during check

**Symptom**: Warning about qpdf during `R CMD check`

**Solution**: This is informational only. Install qpdf if desired:
```bash
# Ubuntu/Debian
sudo apt-get install qpdf

# Fedora/RHEL
sudo dnf install qpdf
```

## Verification Checklist

Before submitting to CRAN, verify:

- [ ] `R CMD check --as-cran` passes on Linux
- [ ] All tests pass on Linux
- [ ] Vignettes build successfully on Linux
- [ ] Examples run without errors on Linux
- [ ] Package loads and functions work correctly
- [ ] GitHub Actions CI shows all platforms passing

## Resources

- [R-hub builder](https://builder.r-hub.io/): Test on multiple Linux distributions
- [GitHub Actions for R](https://github.com/r-lib/actions): Pre-configured workflows
- [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html)
- [Rocker Docker Images](https://rocker-project.org/): R Docker containers

## Contact

For platform-specific issues, please file an issue at:
https://github.com/ttarler/tidydp/issues
