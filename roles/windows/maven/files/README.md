# Maven settings

Put the team's `settings.xml` here (currently the attachment on the team's
Maven setup page in Confluence). The maven role copies it to
`<MAVEN_HOME>\conf\settings.xml`, the global settings for every user.

Rules before committing it:
- No real passwords or tokens. Credentials must be environment references:
  `${env.ARTIFACTORY_USERNAME}` and `${env.ARTIFACTORY_API_KEY}`.
- Write the variable names in UPPERCASE. On Windows, Maven only exposes
  environment variables in uppercase; `${env.Artifactory_username}` never resolves.
