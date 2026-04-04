up:
  docker compose up -d

down:
  docker compose down

logs:
  docker compose logs -f

db:
  docker compose exec db psql -U postgres -d inventory_thesis

rsh:
  docker compose exec ingestion /bin/sh

s:
  df -h | grep -i nvme
