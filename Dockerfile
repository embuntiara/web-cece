# Stage 1: Build stage dengan Composer
FROM laravelsail/php83-composer as build

WORKDIR /var/www/html

# Copy composer files dulu supaya cache efisien
COPY composer.json composer.lock ./

# Install dependencies Laravel tanpa dev package
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Copy semua source code
COPY . .

# Set permission untuk storage & bootstrap
RUN chmod -R 777 storage bootstrap/cache

# Generate autoload optimized
RUN composer dump-autoload --optimize

# Stage 2: Runtime stage
FROM php:8.3-fpm

WORKDIR /var/www/html

# Install ekstensi PHP yang dibutuhkan Laravel
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev zip git unzip && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd pdo_mysql bcmath

# Copy hasil build dari stage 1
COPY --from=build /var/www/html /var/www/html

# Expose port PHP-FPM
EXPOSE 9000

# Jalankan PHP-FPM sebagai default
CMD ["php-fpm"]

# Jika mau untuk development dengan artisan serve, bisa ganti CMD ini:
# CMD ["php","artisan","serve","--host=0.0.0.0","--port=8000"]
