# Dockerfile
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Prevent Python from writing .pyc files and buffering output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y build-essential libpq-dev

# Copy dependency list
COPY requirements.txt .

# Install dependencies (including gunicorn)
RUN pip install --upgrade pip && pip install -r requirements.txt && pip install gunicorn

# Copy project files
COPY . .

# Collect static files (optional for build-time optimization)
RUN python manage.py collectstatic --noinput || true

# Expose port
EXPOSE 8000

# Default command (can be overridden in docker-compose.yml)
CMD ["gunicorn", "Movie_Tiket_Booking.wsgi:application", "--bind", "0.0.0.0:8000"]

