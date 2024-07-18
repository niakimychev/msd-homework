FROM python:3.9-slim

WORKDIR /app

RUN pip install flask requests pandas

COPY . /app

EXPOSE 5000

ENV TOKEN tS5nFh64u7

CMD ["python", "app.py"]
