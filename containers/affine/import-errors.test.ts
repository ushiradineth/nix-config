import assert from "node:assert/strict"
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"
import vm from "node:vm"
import {
  patchWebClient,
  propagateSnapshotErrors,
  rejectEmptySnapshotImport,
} from "./import-errors.ts"

const functionBody =
  'let i=1===t.length?t[0]:null;if(!i)throw Error("Expected a single zip file for snapshot import");return{docIds:(await eC.b.importDocs(e,(0,W.yH)(),i)).filter(e=>void 0!==e).map(e=>e.id)}'
const bundle = `snapshot:{fileOptions:{},importFunction:async({docCollection:e,files:t})=>{${functionBody}}},dotaffinefile:{}`
function importFunction(source: string, pages: unknown[]) {
  const start = source.indexOf("importFunction:async") + "importFunction:".length
  const end = source.indexOf("},dotaffinefile:")
  const code = source.slice(start, end)
  const context = { eC: { b: { importDocs: async () => pages } }, W: { yH: () => ({}) } }
  return vm.runInNewContext(`(${code})`, context) as (input: {
    docCollection: object
    files: object[]
  }) => Promise<{ docIds: string[] }>
}

test("zero-page and partial Snapshot imports reject rather than report success", async () => {
  const input = { docCollection: {}, files: [{ name: "fixture.bs.zip", size: 123 }] }
  const baseline = await importFunction(bundle, [])(input)
  assert.equal(baseline.docIds.length, 0)
  const patched = rejectEmptySnapshotImport(bundle)
  await assert.rejects(
    importFunction(patched, [])(input),
    /no importable pages: fixture\.bs\.zip \(123 bytes\)/u
  )
  await assert.rejects(
    importFunction(patched, [{ id: "valid" }, undefined])(input),
    /Partial data may exist/u
  )
  const valid = await importFunction(patched, [{ id: "first" }, { id: "second" }])(input)
  assert.equal(JSON.stringify(valid.docIds), JSON.stringify(["first", "second"]))
})

test("an unexpected upstream error handler is rejected", () => {
  assert.throws(
    () => propagateSnapshotErrors("different build"),
    /Expected one snapshot error handler/u
  )
})

const fixture = process.env.AFFINE_WORKER_FIXTURE
test("both public and self-hosted HTML load the cache-busted patched bundle", async (t) => {
  const root = await mkdtemp(join(tmpdir(), "affine-web-test-"))
  t.after(() => rm(root, { recursive: true }))
  await mkdir(join(root, "js"))
  const original = `const options={${bundle}};async function convert(){try{}catch(e){console.error("Error when transforming snapshot to doc:"),console.error(e);return}}`
  await writeFile(join(root, "js/index.upstream.js"), original)
  for (const html of ["index.html", "selfhost.html"]) {
    await writeFile(join(root, html), '<html><script src="/js/index.upstream.js"></script></html>')
  }
  await patchWebClient(root)
  for (const html of ["index.html", "selfhost.html"]) {
    const content = await readFile(join(root, html), "utf8")
    const src = content.match(/src="([^"]+)"/u)?.[1]
    assert.ok(src)
    assert.notEqual(src, "/js/index.upstream.js")
    const patched = await readFile(join(root, src), "utf8")
    assert.doesNotThrow(() => new Function(patched))
  }
  assert.equal(await readFile(join(root, "js/index.upstream.js"), "utf8"), original)
})

test(
  "the deployed Transformer exposes its original conversion error",
  { skip: !fixture },
  async () => {
    if (!fixture) throw new Error("Missing fixture path")
    const source = await readFile(fixture, "utf8")
    function transformer(bundle: string) {
      const stop = bundle.lastIndexOf("let zv=new StoreManagerConsumer")
      const suffix = bundle.lastIndexOf("})()})();")
      if (stop < 0 || suffix < stop) throw new Error("Worker fixture layout changed")
      const code =
        bundle.slice(0, stop) + "globalThis.__transformer=Transformer;" + bundle.slice(suffix)
      const getConstructor = new Function(`${code}\nreturn globalThis.__transformer;`)
      const Constructor = getConstructor() as new (options: object) => {
        snapshotToDoc: (snapshot: unknown) => Promise<unknown>
      }
      return new Constructor({
        schema: { flavourSchemaMap: new Map() },
        docCRUD: {},
        blobCRUD: {},
        middlewares: [],
      })
    }
    const baseline = transformer(source)
    assert.equal(await baseline.snapshotToDoc({ type: "invalid" }), undefined)
    const patched = transformer(propagateSnapshotErrors(source))
    await assert.rejects(patched.snapshotToDoc({ type: "invalid" }))
  }
)
