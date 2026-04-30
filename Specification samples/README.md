# Specification Samples

Offline specifications for testing OpenAPI Client Wizard generation.

- `swagger-2-store.json`: compact Swagger 2.0 JSON sample.
- `swagger-2-expanded.json`: Swagger 2.0 JSON sample with path, query, header, body, and all common HTTP methods.
- `openapi-3-store.json`: compact OpenAPI 3 JSON sample.
- `openapi-3-expanded.json`: OpenAPI 3 JSON sample with shared path parameters, request bodies, headers, and all common HTTP methods.
- `openapi-3-store.yaml`: compact OpenAPI 3 YAML sample.
- `openapi-3-store.yml`: same compact OpenAPI 3 YAML sample using the alternate `.yml` extension.
- `openapi-3-expanded.yaml`: OpenAPI 3 YAML sample mirroring the expanded JSON coverage.
- `postman-store-collection.json`: compact Postman Collection v2.1 sample.
- `postman-v2.0-store-collection.json`: Postman Collection v2.0 sample.
- `postman-v1-legacy-store-collection.json`: legacy Postman v1-style collection with a top-level `requests` array.

These files intentionally use `https://api.example.com` and small schemas so generated projects can be inspected without depending on a live API.
The expanded Swagger/OpenAPI samples and the Postman collections include nested request bodies so generated request DTO classes can be tested offline.
