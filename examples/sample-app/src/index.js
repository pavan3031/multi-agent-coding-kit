export function greet(name) {
  if (!name) {
    throw new Error("name is required");
  }
  return `Hello, ${name}! This is the multi-agent-coding-kit sample app.`;
}

/* c8 ignore start */
if (process.argv[1] && process.argv[1].endsWith("index.js")) {
  console.log(greet(process.argv[2] ?? "world"));
}
/* c8 ignore stop */
