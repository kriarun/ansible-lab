# Internal CA bundle

Put the bank's internal CA bundle here as `ca-bundle.crt`
(currently the attachment on the team's npm setup page in Confluence).

The node role copies it to `C:\Users\Public\certs\ca-bundle.crt`.
It contains public certificates only - no secrets.

When the bank's CA is renewed, replace the file and note the new expiry below.

- Issued by: <fill in>
- Expires:   <fill in>
