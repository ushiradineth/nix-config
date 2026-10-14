// Static scanner fixtures only. Never build or execute.
package fixtures

import (
    secure "crypto/tls"
    "net/http"
    process "os/exec"
)

func tlsCases() {
    // ruleid: go-disabled-tls-verification
    _ = &secure.Config{InsecureSkipVerify: true}
    // ruleid: go-disabled-tls-verification
    _ = secure.Config{ServerName: "example.invalid", InsecureSkipVerify: true}
    // ok: go-disabled-tls-verification
    _ = &secure.Config{InsecureSkipVerify: false}
    // ok: go-disabled-tls-verification
    _ = &secure.Config{ServerName: "example.invalid"}
}

func handler(w http.ResponseWriter, r *http.Request) {
    command := r.URL.Query().Get("command")
    copied := command
    // ruleid: go-http-to-shell
    process.Command("sh", "-c", copied).Run()
    // ruleid: go-http-to-shell
    process.Command("/bin/bash", "-c", r.FormValue("command")).Run()
    // ok: go-http-to-shell
    process.Command("printf", "%s", command).Run()
    // ok: go-http-to-shell
    process.Command("sh", "-c", "printf fixed").Run()
}
