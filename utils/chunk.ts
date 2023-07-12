const chunk = (input: any[], size: number) => {
  return input.reduce((arr: any[], item: any, idx: number) => {
    return idx % size === 0
      ? [...arr, [item]]
      : [...arr.slice(0, -1), [...arr.slice(-1)[0], item]]
  }, [])
}

export default chunk
