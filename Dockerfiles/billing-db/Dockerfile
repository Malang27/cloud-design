FROM postgres:15-alpine

# Les variables d'environnement seront définies par docker-compose
# POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD

# Exposer le port PostgreSQL
EXPOSE 5432

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1

# Utiliser l'entrypoint par défaut de postgres
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]