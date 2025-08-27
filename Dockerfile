# White-label Flowise (painel + chat) — gerado no navegador
ARG FLOWISE_TAG=v3.0.2
ARG BRAND_NAME=Sisaitony

FROM node:20 AS build
ARG FLOWISE_TAG
ARG BRAND_NAME
WORKDIR /src
RUN apt-get update && apt-get install -y git jq && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/FlowiseAI/Flowise.git . \
 && (git checkout ${FLOWISE_TAG} || true)
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copia marca
COPY brand.json /tmp/brand.json
COPY logo.svg ui/src/assets/logo.svg
# (opcional)
# COPY favicon.ico ui/public/favicon.ico

# Aplica título/rodapé
RUN set -eux; \
  TITLE=$(jq -r .title /tmp/brand.json 2>/dev/null || echo "${BRAND_NAME}"); \
  FOOTER=$(jq -r .footer /tmp/brand.json 2>/dev/null || echo ""); \
  find ui -type f \( -name '*.tsx' -o -name '*.ts' -o -name '*.jsx' -o -name '*.js' -o -name '*.html' \) -print0 \
    | xargs -0 sed -i -e "s/Flowise/${TITLE}/g" -e "s/Powered by Flowise/${FOOTER}/g"

# Build
RUN pnpm install --frozen-lockfile && pnpm build

FROM node:20
WORKDIR /app
ENV PORT=3000
COPY --from=build /src .
EXPOSE 3000
CMD ["pnpm","start"]
