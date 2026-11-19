# Implementation status

## Included in this first source drop

- SwiftUI app shell and dark dashboard.
- QR scanner and manual pairing-link input.
- One-time QR pairing flow against the PhoneBox Agent `/api/pair/claim` endpoint.
- SHA-256 leaf-certificate pinning for pairing and authenticated requests.
- Keychain persistence for the paired PC credentials.
- `/api/state` polling.
- SSE transport skeleton for `/api/stream`.
- Basic command deck and `/api/trackpad` gesture forwarding.
- GitHub Actions macOS simulator build workflow, usable from a Windows-only workstation.

## Not yet complete

The upstream Android app contains many more screens, widgets, native bridges and request payloads. They have not all been ported in this first source drop. The current dashboard is a functional starting point, not full feature parity.

Before device use, verify the exact JSON response from `ClaimPairingAsync` in the pinned PhoneBox Agent revision. If its response field names differ from `PairClaimReply`, adjust that DTO. Also validate `/api/state` shape and command payloads against the selected upstream revision.

## Security and networking

- Do not disable TLS validation.
- Do not put the bearer token in the QR code.
- Do not send commands until the certificate pin has been checked.
- Use the agent's own LAN allow-list; HTTP 403 for unsupported endpoints is expected.
- iOS background execution is limited. Keep the dashboard active for live monitoring; use push notifications only if a separate push service is later added.
