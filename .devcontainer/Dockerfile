# Dev Container image: JDK 17 + Android SDK cmdline-tools, platform 35, build-tools,
# and an emulator system image for local instrumented-test runs.
FROM eclipse-temurin:17-jdk-jammy

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_HOME=/opt/android-sdk \
    CMDLINE_TOOLS_VERSION=11076708

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    python3 \
    python3-pip \
    libgl1 \
    qemu-kvm \
    && rm -rf /var/lib/apt/lists/*

# Android cmdline-tools (bootstrap, then let sdkmanager manage the rest)
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    curl -sSL -o /tmp/cmdline-tools.zip \
      "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:${PATH}"

# Core SDK packages: platform 35, build-tools, platform-tools, and one emulator
# image for local instrumented-test runs (skip in resource-constrained CI —
# the GitHub Actions emulator runner action provisions its own).
RUN yes | sdkmanager --licenses > /dev/null && \
    sdkmanager \
      "platform-tools" \
      "platforms;android-35" \
      "build-tools;35.0.0" \
      "emulator" \
      "system-images;android-35;google_apis;x86_64" \
      > /dev/null

# pre-commit for the repo-wide hooks
RUN pip3 install --no-cache-dir pre-commit

# Create a non-root user for development
RUN useradd -m -s /bin/bash vscode && chown -R vscode:vscode ${ANDROID_SDK_ROOT}
USER vscode
WORKDIR /workspaces/Project-Mobile-Fortress

CMD ["/bin/bash"]
