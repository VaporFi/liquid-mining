export function getEnvValSafe(key: string, required = true): string {
  const endpoint = process.env[key]
  if (!endpoint && required) throw `Missing env var ${key}`
  return endpoint || ''
}
