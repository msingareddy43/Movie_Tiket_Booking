# Use an official Python image
FROM python:3.10-slim

# Set the working directory inside the container
WORKDIR /app

# Prevent Python from writing .pyc files and buffering output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies and clean cache
RUN apt-get update && apt-get install -y build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

# Copy dependency list first for layer caching
COPY requirements.txt .

# Install dependencies (including gunicorn and whitenoise)
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install gunicorn whitenoise

# Copy the rest of the project files
COPY . .

# ✅ Collect static files inside container for WhiteNoise to serve
RUN python manage.py collectstatic --noinput

# Expose the port that Gunicorn will serve on
EXPOSE 8000

# Start Gunicorn (production server)
CMD ["gunicorn", "Movie_Tiket_Booking.wsgi:application", "--bind", "0.0.0.0:8000"]
