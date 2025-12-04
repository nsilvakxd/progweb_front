# Estágio 1: Build do Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos do projeto
COPY . .

# Baixa as dependências e constrói para web
RUN flutter pub get
RUN flutter build web

# Estágio 2: Servidor Nginx para rodar o site
FROM nginx:alpine

# Copia a configuração personalizada do Nginx (veja o arquivo abaixo)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia o build do Flutter para a pasta do Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Expõe a porta 80
EXPOSE 80

# Inicia o Nginx
CMD ["nginx", "-g", "daemon off;"]