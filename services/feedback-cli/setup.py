"""Setup configuration for Fawkes Feedback CLI tool."""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="fawkes-feedback",
    version="0.1.0",
    author="Fawkes Team",
    author_email="team@fawkes.idp",
    description="CLI tool for submitting feedback to Fawkes platform",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/paruff/fawkes",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Build Tools",
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.9",
    install_requires=[
        "click>=8.1.7",
        "requests>=2.31.0",
        "rich>=13.7.0",
        "pydantic>=2.5.0",
        "pyyaml>=6.0.1",
    ],
    entry_points={
        "console_scripts": [
            "fawkes-feedback=feedback_cli.cli:main",
        ],
    },
)
