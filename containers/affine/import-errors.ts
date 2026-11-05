import { createHash } from "node:crypto"
import { readFile, readdir, writeFile } from "node:fs/promises"
import { join, resolve } from "node:path"
import { pathToFileURL } from "node:url"

export function propagateSnapshotErrors(source: string) {
  let matches = 0
  const result = source.replace(
    /console\.error\("Error when transforming snapshot to doc:"\),console\.error\(([\w$]+)\);return/gu,
    (_, variable: string) => {
      matches++
      return `console.error("Error when transforming snapshot to doc:"),console.error(${variable});throw ${variable}`
    }
  )
  if (matches !== 1) throw new Error(`Expected one snapshot error handler, found ${matches}`)
  return result
}

export function rejectEmptySnapshotImport(source: string) {
  const marker = "Expected a single zip file for snapshot import"
  const markerIndex = source.indexOf(marker)
  const start = source.indexOf("return{docIds:", markerIndex)
  const end = source.indexOf("}}},dotaffinefile:", start)
  if (markerIndex < 0 || start < markerIndex || end < start)
    throw new Error("Snapshot import implementation changed")
  const expression = source.slice(start + "return{docIds:".length, end)
  const imported = expression.match(/^\((await .+)\)\.filter\(e=>void 0!==e\)\.map\(e=>e\.id\)$/u)
  if (!imported) throw new Error("Snapshot import result implementation changed")
  const file = imported[1]?.match(/,([\w$]+)\)$/u)?.[1]
  if (!file) throw new Error("Snapshot import file argument changed")
  const replacement = `const importedPages=(${imported[1]});if(!importedPages.length)throw Error("The Snapshot archive contained no importable pages: "+${file}.name+" ("+${file}.size+" bytes). Nothing was imported.");if(importedPages.some(page=>page===undefined))throw Error("Some Snapshot pages failed to import. Partial data may exist; do not retry the archive.");return{docIds:importedPages.map(page=>page.id)}`
  return source.slice(0, start) + replacement + source.slice(end + 1)
}

export async function patchWebClient(staticDirectory: string) {
  const directory = join(staticDirectory, "js")
  const candidates: { name: string; source: string }[] = []
  for (const name of await readdir(directory)) {
    if (!/^index\..+\.js$/u.test(name)) continue
    const source = await readFile(join(directory, name), "utf8")
    if (source.includes("Expected a single zip file for snapshot import"))
      candidates.push({ name, source })
  }
  if (candidates.length !== 1)
    throw new Error(`Expected one web entry bundle, found ${candidates.length}`)
  const candidate = candidates[0]
  if (!candidate) throw new Error("Missing web entry bundle")
  const patched = rejectEmptySnapshotImport(propagateSnapshotErrors(candidate.source))
  const hash = createHash("sha256").update(patched).digest("hex").slice(0, 16)
  const name = `index.import-errors-${hash}.js`
  const htmlFiles = await Promise.all(
    ["index.html", "selfhost.html"].map(async (file) => {
      const path = join(staticDirectory, file)
      const html = await readFile(path, "utf8")
      if (!html.includes(candidate.name))
        throw new Error(`${file} does not reference the entry bundle`)
      return { path, html }
    })
  )
  await writeFile(join(directory, name), patched, { flag: "wx" })
  for (const { path, html } of htmlFiles) {
    await writeFile(
      path,
      html.replaceAll(candidate.name, name) + `\n<!-- affine-import-errors:${hash} -->\n`
    )
  }
  console.log(`AFFiNE web Snapshot errors enabled: ${name}`)
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const directory = process.argv[2]
  if (!directory) throw new Error("Usage: import-errors.ts STATIC_DIRECTORY")
  await patchWebClient(directory)
}
