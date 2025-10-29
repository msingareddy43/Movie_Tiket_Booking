import pytest
from movie.models import Language

@pytest.mark.django_db
def test_language_model_str():
    lang = Language.objects.create(name="English")
    assert str(lang) == "English"

