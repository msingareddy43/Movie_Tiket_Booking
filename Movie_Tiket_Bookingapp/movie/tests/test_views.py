import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_home_page(client):
    """Test that the home page loads successfully"""
    url = reverse('home')  # Make sure 'Home' exists in your urls.py
    response = client.get(url)
    assert response.status_code == 200

@pytest.mark.django_db
def test_admin_page_redirects(client):
    """Admin page should redirect (login required)"""
    response = client.get('/admin/', follow=True)
    assert response.status_code in [200, 302]

@pytest.mark.django_db
def test_invalid_url_returns_404(client):
    """Check if an invalid route returns 404"""
    response = client.get('/no-such-page/')
    assert response.status_code == 404

