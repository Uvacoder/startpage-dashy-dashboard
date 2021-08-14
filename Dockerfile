FROM node:14.17.5-alpine AS BUILD_IMAGE

ARG TARGETPLATFORM
ENV TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}

# Install additional tools needed on arm64 and armv7
RUN \
  case "${TARGETPLATFORM}" in \
    'linux/arm64') apk add --no-cache python make g++ ;; \
    'linux/arm/v7') apk add --no-cache python make g++ ;; \
  esac

# Create and set the working directory
WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 1000000

# Copy over all project files and folders to the working directory
COPY . ./

# Build initial app for production
RUN yarn build

# # remove development dependencies
# RUN yarn install --production --ignore-scripts --prefer-offline

# Build the final image
FROM node:14.17.5-alpine

# Define some ENV Vars
ENV PORT=80 \
    DIRECTORY=/app \
    IS_DOCKER=true

# Create and set the working directory
WORKDIR ${DIRECTORY}

# Install tini and tzdata
RUN apk add --no-cache tzdata tini

# copy from build image
COPY --from=BUILD_IMAGE /app ./

# Finally, run start command to serve up the built application
ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "yarn", "build-and-start" ]

# Expose given port
EXPOSE ${PORT}
