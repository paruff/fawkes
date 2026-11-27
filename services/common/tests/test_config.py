from fawkes_common.config import ServiceSettings


class Settings(ServiceSettings):
    service_name: str = "example"


def test_defaults():
    settings = Settings(_env_file=None)

    assert settings.service_name == "example"
    assert settings.version == "0.1.0"
    assert settings.debug is False


def test_environment_overrides_defaults_ignoring_case(monkeypatch):
    monkeypatch.setenv("DEBUG", "true")
    monkeypatch.setenv("version", "2.0.0")

    settings = Settings(_env_file=None)

    assert settings.debug is True
    assert settings.version == "2.0.0"


def test_reads_dotenv_file_and_skips_unrelated_keys(tmp_path, monkeypatch):
    (tmp_path / ".env").write_text("VERSION=3.0.0\nSOME_OTHER_SERVICE_KEY=x\n")
    monkeypatch.chdir(tmp_path)

    assert Settings().version == "3.0.0"
