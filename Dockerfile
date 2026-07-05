# create server image > create /app (set as working dir) > requirements file > copy over contents > and run app

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY shortener/ shortener/

EXPOSE 8000

CMD ["uvicorn", "shortener.main:app", "--host", "0.0.0.0", "--port", "8000"]