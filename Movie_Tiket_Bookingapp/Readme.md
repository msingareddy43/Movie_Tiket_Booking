# 🎬 Movie Ticket Booking App (Cloud-Ready Django Project)

A **Django + PostgreSQL + Nginx + Gunicorn** web application that allows users to view and book movie tickets online.
This project is fully containerized with **Docker** and tested via **pytest**.
You can run it manually or via **Docker Compose** for production-ready deployment.

---

## 🧱 Tech Stack

| Layer                 | Technology                                  |
| --------------------- | ------------------------------------------- |
| **Frontend**          | HTML, CSS, Bootstrap (via Django templates) |
| **Backend**           | Django 5.2.7                                |
| **Database**          | PostgreSQL 15                               |
| **Server**            | Gunicorn + Nginx                            |
| **Testing**           | Pytest + pytest-django                      |
| **Containerization**  | Docker, Docker Compose                      |
| **CI/CD (Next Step)** | Jenkins Pipeline                            |

---

## 📂 Project Structure

```
Movie_Tiket_Bookingapp/
├── movie/                        # Main Django app
├── static/                       # Static assets
├── templates/                    # HTML templates
├── requirements.txt              # Python dependencies
├── Dockerfile                    # Build web container
├── docker-compose.yml            # Run full stack (App + DB + Nginx)
├── pytest.ini                    # Pytest configuration
├── manage.py                     # Django entry point
└── README.md                     # This file
```

---

## ⚙️ Prerequisites

Before running manually or via Docker, ensure you have:

| Dependency         | Minimum Version | Install Command (Ubuntu)                                  |
| ------------------ | --------------- | --------------------------------------------------------- |
| **Python**         | 3.10+           | `sudo apt install python3 python3-venv python3-pip`       |
| **PostgreSQL**     | 15+             | `sudo apt install postgresql postgresql-contrib`          |
| **Docker**         | 24+             | [Install Docker](https://docs.docker.com/engine/install/) |
| **Docker Compose** | v2+             | `sudo apt install docker-compose-plugin`                  |
| **Git**            | Latest          | `sudo apt install git`                                    |

---

## 🚀 Run Manually (Without Docker)

1. **Clone the repository**

   ```bash
   git clone https://github.com/<your-username>/Movie_Tiket_Bookingapp.git
   cd Movie_Tiket_Bookingapp
   ```

2. **Create and activate a virtual environment**

   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies**

   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   Create a `.env` file in the root directory:

   ```ini
   DEBUG=True
   SECRET_KEY=your_secret_key_here
   DATABASE_URL=postgres://postgres:postgres@localhost:5432/movie_db
   ```

5. **Setup the database**

   ```bash
   sudo -u postgres psql -c "CREATE DATABASE movie_db;"
   python manage.py migrate
   python manage.py createsuperuser
   ```

6. **Run the application**

   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

7. Visit:
   👉 [http://localhost:8000](http://localhost:8000)

---

## 🐳 Run via Docker (Recommended)

1. **Clone the repository**

   ```bash
   git clone https://github.com/<your-username>/Movie_Tiket_Bookingapp.git
   cd Movie_Tiket_Bookingapp
   ```

2. **Build and run containers**

   ```bash
   docker compose up -d --build
   ```

3. **Verify containers**

   ```bash
   docker ps
   ```

4. **Run tests (Pytest)**

   ```bash
   docker compose run --rm test
   ```

5. **Access the application**

   * Nginx Reverse Proxy → [http://localhost](http://localhost)
   * Django App (direct) → [http://localhost:8000](http://localhost:8000)
   * PostgreSQL → Port `5432`

6. **Stop containers**

   ```bash
   docker compose down
   ```

---

## 🧪 Run Tests Manually (Optional)

If you want to test without Docker:

```bash
pytest -v --ds=Movie_Tiket_Booking.settings
```

---

## 🧰 Environment Variables Summary

| Variable       | Description                  | Example                                         |
| -------------- | ---------------------------- | ----------------------------------------------- |
| `DEBUG`        | Enables Django debug mode    | `True`                                          |
| `SECRET_KEY`   | Django secret key            | `mysecretkey`                                   |
| `DATABASE_URL` | PostgreSQL connection string | `postgres://postgres:postgres@db:5432/movie_db` |

---

## 🌍 Deployment Overview

When run via `docker-compose`, the app uses:

* `postgres_db`: PostgreSQL 15 container
* `django_app`: Django + Gunicorn web app
* `nginx_server`: Nginx reverse proxy serving port **80**
* `django_test_runner`: Executes `pytest` automatically during CI/CD

---

## 📸 Example Output

### ✅ Test Results

```
============================== test session starts ==============================
platform linux -- Python 3.10.19, pytest-8.4.2
django: version: 5.2.7
collected 4 items

movie/tests/test_models.py::test_language_model_str PASSED
movie/tests/test_views.py::test_home_page PASSED
movie/tests/test_views.py::test_admin_page_redirects PASSED
movie/tests/test_views.py::test_invalid_url_returns_404 PASSED
============================== 4 passed in 1.54s ===============================
```

### 🌐 Access URLs

| Service             | URL                                              |
| ------------------- | ------------------------------------------------ |
| Web App             | [http://localhost](http://localhost)             |
| Admin Panel         | [http://localhost/admin](http://localhost/admin) |
| Database (Postgres) | Port `5432`                                      |

---

## 👨‍💻 Author

**Developed by:** Your Name
**GitHub:** [github.com/your-username](https://github.com/your-username)
**Project Type:** Cloud-Based Django Web App (Dockerized)
**Use Case:** For DevOps & Cloud Automation Demonstrations

---

## 🧩 Next Steps

* Integrate Jenkins CI/CD
* Push images to Docker Hub / AWS ECR
* Deploy on AWS EC2 or ECS
* Add monitoring with Prometheus + Grafana

---

**🎉 The project is fully operational both manually and via Docker.**

