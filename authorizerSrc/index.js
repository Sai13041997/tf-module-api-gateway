const jwt = require("jsonwebtoken");
const jwksClient = require("jwks-rsa");

function policy(effect, principalId, resource, context) {
  return {
    principalId,
    policyDocument: {
      Version: "2012-10-17",
      Statement: [{ Action: "execute-api:Invoke", Effect: effect, Resource: resource }],
    },
    context: context || {},
  };
}

function deny(principalId, resource) {
  return policy("Deny", principalId, resource);
}

function allow(principalId, resource, context) {
  return policy("Allow", principalId, resource, context);
}

exports.handler = async (event) => {
  const issuer = process.env.JWT_ISSUER; // https://sts.windows.net/<tenant>/
  const audList = (process.env.JWT_AUDIENCE || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

  const auth = event.authorizationToken || "";
  const m = auth.match(/^Bearer\s+(.+)$/i);
  if (!m) {
    console.warn("AUTHZ_DENY: missing/invalid Authorization header format (expected Bearer)");
    return deny("anonymous", event.methodArn);
  }

  const token = m[1];

  const tenantMatch = issuer.match(/sts\.windows\.net\/([^/]+)\//i);
  const tenantId = tenantMatch ? tenantMatch[1] : null;

  // FIX: use v2.0 keys endpoint (matches your well-known config jwks_uri)
  const jwksUri = tenantId
    ? `https://login.microsoftonline.com/${tenantId}/discovery/v2.0/keys`
    : "https://login.microsoftonline.com/common/discovery/v2.0/keys";

  const client = jwksClient({
    jwksUri,
    cache: true,
    cacheMaxEntries: 5,
    cacheMaxAge: 10 * 60 * 1000,
    rateLimit: true,
    jwksRequestsPerMinute: 10,
    timeout: 5000,
  });

  const getKey = (header, cb) => {
    client.getSigningKey(header.kid, (err, key) => {
      if (err) return cb(err);
      cb(null, key.getPublicKey());
    });
  };

  try {
    const decoded = await new Promise((resolve, reject) => {
      jwt.verify(
        token,
        getKey,
        {
          issuer,
          audience: audList.length ? audList : undefined,
          algorithms: ["RS256"],
          clockTolerance: 60,
        },
        (err, payload) => (err ? reject(err) : resolve(payload))
      );
    });

    const principalId = decoded.oid || decoded.sub || "user";

    return allow(principalId, event.methodArn, {
      oid: decoded.oid || "",
      tid: decoded.tid || "",
      sub: decoded.sub || "",
      aud: typeof decoded.aud === "string" ? decoded.aud : "",
      iss: typeof decoded.iss === "string" ? decoded.iss : "",
    });
  } catch (e) {
    // DEBUG: capture the real reason (do not log the token)
    let headerKid;
    try {
      const d = jwt.decode(token, { complete: true }) || {};
      headerKid = d && d.header ? d.header.kid : undefined;
    } catch (_) {}

    console.error("AUTHZ_DENY verify failed", {
      name: e?.name,
      code: e?.code,
      message: e?.message,
      jwksUri,
      headerKid,
      issuer,
      audiences: audList,
      now: new Date().toISOString(),
    });

    return deny("unauthorized", event.methodArn);
  }
};
