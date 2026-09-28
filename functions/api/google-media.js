export async function onRequestGet({ env }) {
  const required = [
    "GOOGLE_CLIENT_ID",
    "GOOGLE_CLIENT_SECRET",
    "GOOGLE_REFRESH_TOKEN",
    "GOOGLE_ACCOUNT_ID",
    "GOOGLE_LOCATION_ID"
  ];
  const missing = required.filter((key) => !env[key]);
  if (missing.length) {
    return json({ ok:false, error:"Google Business Profile media integration is not configured yet.", missing });
  }

  try {
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: env.GOOGLE_CLIENT_ID,
        client_secret: env.GOOGLE_CLIENT_SECRET,
        refresh_token: env.GOOGLE_REFRESH_TOKEN,
        grant_type: "refresh_token"
      })
    });

    const tokenData = await tokenResponse.json();
    if (!tokenResponse.ok || !tokenData.access_token) {
      return json({ ok:false, error:"Unable to refresh the Google access token." }, 502);
    }

    const parent = `accounts/${env.GOOGLE_ACCOUNT_ID}/locations/${env.GOOGLE_LOCATION_ID}`;
    const url = new URL(`https://mybusiness.googleapis.com/v4/${parent}/media`);
    url.searchParams.set("pageSize", "100");

    const mediaResponse = await fetch(url, {
      headers: { Authorization: `Bearer ${tokenData.access_token}` }
    });
    const mediaData = await mediaResponse.json();

    if (!mediaResponse.ok) {
      return json({
        ok:false,
        error:"Google Business Profile Media API request failed.",
        details: mediaData?.error?.message || "Unknown Google API error."
      }, mediaResponse.status);
    }

    const items = Array.isArray(mediaData.mediaItems) ? mediaData.mediaItems : [];
    items.sort((a,b) => new Date(b.createTime || 0) - new Date(a.createTime || 0));

    return json({
      ok:true,
      updatedAt:new Date().toISOString(),
      items:items.map((item) => ({
        name:item.name || "",
        mediaFormat:item.mediaFormat || "PHOTO",
        imageUrl:item.thumbnailUrl || item.googleUrl || "",
        googleUrl:item.googleUrl || "",
        createTime:item.createTime || null,
        description:item.description || "",
        category:item.locationAssociation?.category || "",
        attribution:item.attribution || null
      }))
    }, 200, {
      "Cache-Control":"public, max-age=300, s-maxage=300"
    });
  } catch (error) {
    return json({ ok:false, error:"Unexpected Google Business Profile media error." }, 500);
  }
}

function json(data, status=200, extraHeaders={}) {
  return new Response(JSON.stringify(data), {
    status,
    headers:{
      "content-type":"application/json; charset=utf-8",
      "Cache-Control":"no-store",
      ...extraHeaders
    }
  });
}
