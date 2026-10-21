# Internal CA bundle

Put the bank's internal CA bundle here as `ca-bundle.crt`
(currently the attachment on the team's setup page in Confluence).

The ca_bundle role copies it to `ca_bundle_path` (group_vars, default
`C:\Users\Public\certs\ca-bundle.crt`). Used by npm (cafile) and pip (cert).
It contains public certificates only - no secrets.

When the bank's CA is renewed, replace the file and note the new expiry below.

- Issued by: <fill in>
- Expires:   <fill in>
