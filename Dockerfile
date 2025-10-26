# Gunakan image Laravel yang sudah siap Composer & PHP
FROM laravelsail/php83-composer as build

WORKDIR /var/www/html

# Copy file composer terlebih dahulu agar cache efisien
COPY composer.json composer.lock ./

# Install dependencies Laravel tanpa dev package
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Copy semua source code ke dalam container
COPY . .

# Set permission untuk storage & bootstrap
RUN chmod -R 777 storage bootstrap/cache

# Generate autoload
RUN composer dump-autoload --optimize

# Gunakan image final untuk runtime (lebih ringan)
FROM php:8.3-fpm

WORKDIR /var/www/html

# Install ekstensi PHP dasar untuk Laravel
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev zip git unzip && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd pdo_mysql bcmath

# Copy hasil build dari stage sebelumnya
COPY --from=build /var/www/html /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
