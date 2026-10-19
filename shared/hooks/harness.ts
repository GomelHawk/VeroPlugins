// Not a plugin. `claude plugin test shared` needs a hooks module to load before it runs
// shared/tests/source-check.test.ts; this one registers nothing. The real module of each plugin
// imports hooks/source-check.ts, its byte-identical copy of shared/hooks/source-check.ts.
export default function register(): void {}
