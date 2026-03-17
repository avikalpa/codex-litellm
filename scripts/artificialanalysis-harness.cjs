const { mkdir, writeFile } = require("node:fs/promises");
const path = require("node:path");
const { chromium } = require("playwright");

const rootDir = process.cwd();
const logsDir = path.join(rootDir, "logs");
const profileDir = process.env.AA_CHROMIUM_PROFILE_DIR || path.join(logsDir, "aa-profile");
const homeUrl = "https://artificialanalysis.ai/";
const gdpvalUrl = "https://artificialanalysis.ai/evaluations/gdpval-aa";

function uniqueSorted(values) {
  return [...new Set(values)].sort((left, right) => left.localeCompare(right));
}

function extractModelSlugs(hrefs) {
  return uniqueSorted(
    hrefs
      .map((href) => {
        try {
          return new URL(href, homeUrl).pathname;
        } catch {
          return "";
        }
      })
      .filter((pathname) => pathname.startsWith("/models/"))
      .map((pathname) => pathname.replace(/^\/models\//, ""))
      .map((slug) => slug.replace(/\/providers$/, ""))
      .filter(Boolean),
  );
}

function extractModelSlugsFromHtml(html) {
  return uniqueSorted(
    [...html.matchAll(/\/models\/([A-Za-z0-9._-]+)(?:\/providers)?/g)]
      .map((match) => match[1])
      .filter(Boolean),
  );
}

async function main() {
  await mkdir(logsDir, { recursive: true });

  const context = await chromium.launchPersistentContext(profileDir, {
    headless: true,
    viewport: { width: 1440, height: 2200 },
  });

  try {
    const page = context.pages()[0] || (await context.newPage());

    await page.goto(homeUrl, { waitUntil: "networkidle", timeout: 120000 });
    await page.screenshot({
      path: path.join(logsDir, "aa-home.png"),
      fullPage: true,
    });

    const homeTitle = await page.title();
    const homeHrefs = await page.$$eval("a[href]", (anchors) =>
      anchors.map((anchor) => anchor.href).filter(Boolean),
    );
    const homeSlugs = uniqueSorted([
      ...extractModelSlugs(homeHrefs),
      ...extractModelSlugsFromHtml(await page.content()),
    ]);
    const gdpvalHref =
      homeHrefs.find((href) => href.includes("/evaluations/gdpval-aa")) || gdpvalUrl;

    await page.goto(gdpvalHref, { waitUntil: "networkidle", timeout: 120000 });
    await page.screenshot({
      path: path.join(logsDir, "aa-gdpval.png"),
      fullPage: true,
    });

    const gdpvalTitle = await page.title();
    const gdpvalHrefs = await page.$$eval("a[href]", (anchors) =>
      anchors.map((anchor) => anchor.href).filter(Boolean),
    );
    const gdpvalSlugs = uniqueSorted([
      ...extractModelSlugs(gdpvalHrefs),
      ...extractModelSlugsFromHtml(await page.content()),
    ]);
    const bodyText = await page.locator("body").innerText();

    const slugReport = {
      generatedAt: new Date().toISOString(),
      pageUrl: homeUrl,
      gdpvalUrl: page.url(),
      homeTitle,
      gdpvalTitle,
      homeSlugs,
      gdpvalSlugs,
    };

    const evidenceReport = {
      generatedAt: new Date().toISOString(),
      finalUrl: page.url(),
      steps: [
        { step: "home", url: homeUrl, title: homeTitle },
        { step: "gdpval-aa", url: page.url(), title: gdpvalTitle },
      ],
      phraseChecks: {
        hasGdpval: /GDPval-AA/i.test(bodyText),
        hasAgentic: /\bagentic\b/i.test(bodyText),
        hasToolUse: /\btool\b/i.test(bodyText) || /\btools\b/i.test(bodyText),
        hasCoding: /\bcoding\b/i.test(bodyText) || /\bcode\b/i.test(bodyText),
      },
      bodyExcerpt: bodyText.replace(/\s+/g, " ").slice(0, 1200),
    };

    await writeFile(
      path.join(logsDir, "artificialanalysis-model-slugs.json"),
      `${JSON.stringify(slugReport, null, 2)}\n`,
      "utf8",
    );
    await writeFile(
      path.join(logsDir, "aa-agentic-click-report.json"),
      `${JSON.stringify(evidenceReport, null, 2)}\n`,
      "utf8",
    );
  } finally {
    await context.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
