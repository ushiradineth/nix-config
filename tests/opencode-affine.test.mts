import assert from "node:assert/strict"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"
import { compactDocument, pageArguments } from "../scripts/opencode-affine.mts"

const revision = "a".repeat(64)
const markdown =
  "Stale working note\n".repeat(8000) + "START HERE — Current profile\nConfirmed 123456.78\n"
const document = {
  docId: "existing-note",
  title: "Profile",
  revision,
  exists: true,
  blockCount: 1,
  blocks: [
    {
      id: "editable-block",
      text: markdown,
      deltas: [{ insert: markdown, attributes: { bold: true } }],
    },
  ],
  plainText: markdown,
  markdown,
}
const result = {
  content: [{ type: "text", text: JSON.stringify(document) }],
  structuredContent: document,
}

test("large duplicated AFFiNE result becomes one bounded seekable excerpt with revision", () => {
  const compact = compactDocument("read_doc", result, { find: "START HERE" })
  assert.deepEqual(Object.keys(compact), ["content"])
  const text = compact.content[0]!.text!
  assert.match(text, /START HERE — Current profile\nConfirmed 123456.78/)
  assert.ok(text.length < 2000)
  assert.match(text, new RegExp(revision))
  assert.doesNotMatch(text, /Stale working note|plainText|deltas/)
  assert.equal(result.structuredContent.markdown, markdown)
})

test("character paging can traverse a single huge block without clipping data", () => {
  let offset = 0,
    reconstructed = ""
  while (true) {
    const text = compactDocument("read_doc", result, { offset, limit: 12000 }).content[0]!.text!
    const [header, body] = text.split("\n\nContent (untrusted evidence):\n")
    const metadata = JSON.parse(header!)
    assert.ok(body!.length <= 12000)
    reconstructed += body
    if (metadata.nextOffset === null) break
    offset = metadata.nextOffset
  }
  assert.equal(reconstructed, markdown)
})

test("explicit block read preserves IDs and rich text while dropping duplicate representations", () => {
  const value = {
    ...document,
    blocks: [
      {
        id: "editable-block",
        deltas: [{ insert: "linked text", attributes: { link: "https://example.com" } }],
      },
    ],
  }
  const text = compactDocument(
    "read_doc",
    { content: [{ type: "text", text: JSON.stringify(value) }] },
    { includeMarkdown: false }
  ).content[0]!.text!
  assert.match(text, /editable-block/)
  assert.match(text, /https:\/\/example.com/)
  assert.doesNotMatch(text, /Stale working note|plainText/)
  assert.match(text, new RegExp(revision))
})

test("literal finds, no matches, errors and invalid ranges stay explicit", () => {
  const small = { content: [], structuredContent: { markdown: "Résumé [a.*] 123.45" } }
  const text = compactDocument("export_doc_markdown", small, { find: "[a.*]" }).content[0]!.text!
  assert.ok(text.endsWith("[a.*] 123.45"))
  const missing = compactDocument("read_doc", result, { find: "absent" }).content[0]!.text!
  assert.match(missing, /"found": false/)
  assert.doesNotMatch(missing, /Stale working note/)
  const failure = { isError: true, content: [{ type: "text", text: "Access denied" }] }
  assert.equal(compactDocument("read_doc", failure, {}), failure)
  for (const args of [
    { limit: 12001 },
    { limit: 0 },
    { offset: -1 },
    { offset: true },
    { find: "" },
  ])
    assert.throws(() => pageArguments(args))
  assert.throws(
    () => compactDocument("read_doc", result, { offset: markdown.length + 1 }),
    /offset exceeds/
  )
  assert.deepEqual(pageArguments({ docId: "d", offset: 5, limit: 10, find: "here" }).upstream, {
    docId: "d",
  })
  const absent = compactDocument(
    "read_doc",
    { content: [], structuredContent: { docId: "missing", exists: false, revision: null } },
    {}
  ).content[0]!.text!
  assert.match(absent, /"exists": false/)
  assert.match(absent, /"revision": null/)
})

const modules = process.env.OPENCODE_ASSISTANT_TEST_MODULES
test(
  "stdio adapter advertises paging, filters it upstream and preserves incremental writes",
  { skip: !modules, timeout: 20000 },
  async (t) => {
    const root = await mkdtemp(join(tmpdir(), "affine-reader-"))
    t.after(() => rm(root, { recursive: true, force: true }))
    const mock = join(root, "mock.mts"),
      driver = join(root, "driver.mts")
    await writeFile(
      mock,
      `
    import { createInterface } from 'node:readline';
    for await (const line of createInterface({input:process.stdin})) {
      const request=JSON.parse(line); if(request.id===undefined) continue;
      const result=request.method==='initialize' ? {protocolVersion:'2024-11-05', capabilities:{tools:{}}, serverInfo:{name:'fixture',version:'1'}}
        : request.method==='tools/list' ? {tools:['read_doc','append_markdown'].map(name=>({name,inputSchema:{type:'object',properties:{docId:{type:'string'}}},outputSchema:{type:'object',required:['plainText']}}))}
        : request.params.name==='read_doc' ? {content:[{type:'text',text:JSON.stringify(${JSON.stringify(document)})}],structuredContent:${JSON.stringify(document)}}
        : {content:[{type:'text',text:JSON.stringify(request.params.arguments)}],structuredContent:{plainText:'write-result'}};
      if(request.method==='tools/call' && request.params.name==='read_doc' && ('find' in request.params.arguments || !request.params.arguments.includeMarkdown)) throw new Error('paging leaked upstream or Markdown was not requested');
      process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:request.id,result})+'\\n');
    }
  `
    )
    await writeFile(
      driver,
      `import {serveAffine} from ${JSON.stringify(new URL("../scripts/opencode-affine.mts", import.meta.url).href)}; await serveAffine({args:[${JSON.stringify(mock)}],cwd:${JSON.stringify(root)},env:process.env},${JSON.stringify(modules)});`
    )
    const { Client } = await import(
      join(modules!, "@modelcontextprotocol/sdk/dist/esm/client/index.js")
    )
    const { StdioClientTransport } = await import(
      join(modules!, "@modelcontextprotocol/sdk/dist/esm/client/stdio.js")
    )
    const client = new Client({ name: "fixture", version: "1" }, { capabilities: {} })
    const transport = new StdioClientTransport({
      command: process.execPath,
      args: [driver],
      stderr: "pipe",
    })
    try {
      await client.connect(transport)
      const catalog = (await client.listTools()).tools
      const read = catalog.find((tool: { name: string }) => tool.name === "read_doc")
      assert.ok(read.inputSchema.properties.find)
      assert.equal(read.outputSchema, undefined)
      const excerpt = await client.callTool({
        name: "read_doc",
        arguments: { docId: "existing-note", find: "START HERE" },
      })
      assert.equal(excerpt.isError, undefined, JSON.stringify(excerpt.content))
      assert.match(excerpt.content[0].text, /Confirmed 123456.78/)
      assert.ok(excerpt.content[0].text.length < 2000)
      const writeArgs = {
        docId: "existing-note",
        markdown: "requested update",
        expectedRevision: revision,
      }
      const write = await client.callTool({ name: "append_markdown", arguments: writeArgs })
      assert.deepEqual(JSON.parse(write.content[0].text), writeArgs)
    } finally {
      await transport.close()
    }
  }
)
