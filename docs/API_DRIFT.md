# API contract and drift testing

API-wrapping CLIs depend on two contracts: the upstream service's published API description, and the requests and responses implemented by the CLI. Keep those contracts visible in review and exercise the client without relying on live credentials.

## 1. Track the upstream contract

Use the provider's canonical OpenAPI document, discovery document, or versioned schema. Record its URL and revision/version in the repository. Prefer a checked-in snapshot or a CI-fetched copy pinned to a known revision; a moving `latest` document alone makes failures hard to reproduce.

Maintain a small inventory of the API operations the CLI actually wraps. For each operation, record:

- stable operation ID, HTTP method, and path;
- required path, query, and header parameters;
- request schema and required fields;
- response schema fields the CLI consumes;
- authentication scopes and relevant deprecation markers.

Compare that inventory with the upstream contract. Report new, removed, renamed, or deprecated operations and missing or changed fields. A change is a review signal: update the inventory and implementation deliberately, or document why the CLI does not need the new API surface. Avoid failing simply because the provider added an unrelated endpoint.

The fleet's discovery-document drift detector demonstrates recursive operation extraction, implementation inventory comparison, and a machine-readable report. Adapt those ideas to the API description used by the new CLI; do not rely on source-text matching as the only proof that a request works.

## 2. Test the request contract

Keep the HTTP transport or service client behind an interface or injectable dependency. For REST clients, use `httptest.Server` or a custom `http.RoundTripper` to assert the actual request and return fixture responses. Cover URL construction, encoding, auth headers, pagination, error mapping, and retry behavior. Do not call production endpoints from unit tests.

For generated SDK clients, use a small typed test double at the service boundary. Configure method callbacks with expected responses/errors and record method names and arguments. Assert both the returned CLI result and the API calls made. This follows the fleet's API test-double approach, where call tracking and configurable service responses keep command tests independent of network access.

Keep fixtures focused on the fields the CLI reads, including optional fields, empty collections, missing values, and representative API errors. When a live sandbox test is valuable, isolate it behind an explicit integration-test build tag and credentials supplied through the environment.

## 3. Check response compatibility

Add focused decode tests for each response type the CLI consumes. A useful contract assertion checks required fields and types while allowing unknown fields so additive upstream changes remain compatible. When the CLI maps API responses to its own output model, test that mapping separately from HTTP transport.

For destructive or stateful endpoints, test request construction and error handling with a fake server. Do not let a contract test mutate a real account.

## 4. Run drift checks in CI

Run deterministic unit and contract tests on every change. Run the drift comparison on a schedule and when the pinned contract revision changes. Have CI publish a JSON or Markdown report as an artifact and fail only for unexplained breaking changes to operations or fields the CLI uses.

Example checks for a Go CLI:

```sh
go test ./...
go vet ./...
go run ./cmd/apidrift --spec ./docs/api/openapi.json --inventory ./docs/api/operations.yaml
```

The drift command and file formats are project-specific; the example names show the intended inputs, not a built-in command from this template.

## Pull request checklist

- [ ] The API contract revision and operation inventory are current.
- [ ] Request tests assert method, path, query, headers, and body where relevant.
- [ ] Response fixtures cover the fields the CLI consumes and relevant errors.
- [ ] Drift findings are reviewed, including any intentionally unsupported changes.
- [ ] Unit and contract checks pass without production credentials.
