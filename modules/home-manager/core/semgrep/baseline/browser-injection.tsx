// Static scanner fixtures only. Never import or execute this file.
import sanitizeHtml from "sanitize-html"
import cleanHtml from "sanitize-html"
import { sanitizeHtml as unrelatedSanitize } from "other-sanitizer"
import { sanitizeHtml as namedSanitize } from "sanitize-html"

function unrelatedImport(element: HTMLElement) {
  // ruleid: browser-url-to-html
  element.innerHTML = unrelatedSanitize(location.hash)
  // ruleid: browser-url-to-html
  element.outerHTML = namedSanitize(location.hash)
}

function shadowedSanitizer(element: HTMLElement, sanitizeHtml: (s: string) => string) {
  // ruleid: browser-url-to-html
  element.innerHTML = sanitizeHtml(location.hash)
}

function lookalikeSanitizer(element: HTMLElement) {
  const sanitizeHtml = (s: string) => s
  // ruleid: browser-url-to-html
  element.innerHTML = sanitizeHtml(location.search)
}

function importedAlias(element: HTMLElement) {
  const source = location.hash
  const cleaned = cleanHtml(source)
  // ok: browser-url-to-html
  element.innerHTML = cleaned
  // ruleid: browser-url-to-html
  element.outerHTML = cleanHtml(source, { allowedAttributes: false })
}

const arrowShadow = (element: HTMLElement, cleanHtml: (s: string) => string) => {
  // ruleid: browser-url-to-html
  element.innerHTML = cleanHtml(location.hash)
}

function declarationShadow(element: HTMLElement) {
  function cleanHtml(value: string) {
    return value
  }
  // ruleid: browser-url-to-html
  element.innerHTML = cleanHtml(location.hash)
}

function mutableShadow(element: HTMLElement) {
  let cleanHtml = (s: string) => s
  // ruleid: browser-url-to-html
  element.innerHTML = cleanHtml(location.hash)
}

const arrowBodyShadow = (element: HTMLElement) => {
  const cleanHtml = (s: string) => s
  // ruleid: browser-url-to-html
  element.innerHTML = cleanHtml(location.hash)
}

const arrowExpressionShadow = (element: HTMLElement, cleanHtml: (s: string) => string) =>
  // ruleid: browser-url-to-html
  (element.innerHTML = cleanHtml(location.hash))

const functionExpressionShadow = function (element: HTMLElement, cleanHtml: (s: string) => string) {
  // ruleid: browser-url-to-html
  element.innerHTML = cleanHtml(location.hash)
}

function unsafeHtml(element: HTMLElement) {
  // ruleid: browser-url-to-html
  element.innerHTML = window.location.hash

  const html = decodeURIComponent(document.location.search)
  // ruleid: browser-url-to-html
  element.outerHTML = html

  // ruleid: browser-url-to-html
  element.insertAdjacentHTML("beforeend", location.href)

  // ruleid: browser-url-to-html
  document.write(window.location.search)

  // ruleid: browser-url-to-html
  return <div dangerouslySetInnerHTML={{ __html: location.hash }} />
}

function unsafeSanitizerOptions(element: HTMLElement) {
  // ruleid: browser-url-to-html
  element.innerHTML = sanitizeHtml(location.hash, { allowedTags: false })
}

function safeHtml(element: HTMLElement) {
  // ok: browser-url-to-html
  element.textContent = window.location.hash

  // ok: browser-url-to-html
  element.innerHTML = "<p>Fixed content</p>"

  const html = sanitizeHtml(window.location.hash)
  // ok: browser-url-to-html
  element.innerHTML = html

  // ok: browser-url-to-html
  return <div dangerouslySetInnerHTML={{ __html: sanitizeHtml(location.search) }} />
}

function unsafeCode() {
  // ruleid: browser-url-to-code
  eval(window.location.hash)

  const code = decodeURIComponent(document.location.search)
  // ruleid: browser-url-to-code
  window.eval(code)

  // ruleid: browser-url-to-code
  new Function("value", location.hash)

  // ruleid: browser-url-to-code
  Function(location.search)

  // ruleid: browser-url-to-code
  setTimeout(window.location.hash, 100)

  // ruleid: browser-url-to-code
  setInterval(document.location.search, 100)
}

function safeCode() {
  // ok: browser-url-to-code
  JSON.parse(window.location.hash)

  // ok: browser-url-to-code
  setTimeout(() => console.log(window.location.hash), 100)

  // ok: browser-url-to-code
  setInterval(() => console.log(document.location.search), 100)
}
