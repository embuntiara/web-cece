FROM php:8.3-fpm

WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git unzip zip curl libpng-dev libjpeg-dev libfreetype6-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy only composer files first
COPY composer.json composer.lock ./

# Install composer dependencies (pakai cache layer)
RUN composer install --no-dev --prefer-dist --no-interaction --no-scripts

# Copy the rest of the project
COPY . .

RUN composer dump-autoload --optimize

CMD ["php-fpm"]
