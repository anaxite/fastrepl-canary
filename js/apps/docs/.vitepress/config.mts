import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vitepress";
import unocss from "unocss/vite";

const sidebar = [
  {
    text: "About Canary",
    link: "/docs",
  },
  {
    text: "Common",
    items: [
      {
        text: "Customization",
        collapsed: true,
        items: [
          {
            text: "Styling",
            link: "/docs/common/customization/styling",
          },
          {
            text: "Built-in components",
            link: "/docs/common/customization/builtin",
          },
          {
            text: "Custom components",
            link: "/docs/common/customization/custom",
          },
        ],
      },
      {
        text: "Guides",
        collapsed: true,
        items: [
          {
            text: "Filtering",
            link: "/docs/common/guides/filtering",
          },
          {
            text: "Conditional Callout",
            link: "/docs/common/guides/conditional-callout",
          },
        ],
      },
    ],
  },
  {
    text: "Local",
    items: [
      {
        text: "Demo",
        link: "/docs/local/demo",
      },
      {
        text: "Introduction",
        link: "/docs/local/intro",
      },
      {
        text: "Integrations",
        collapsed: true,
        items: [
          {
            text: "Docusaurus",
            link: "/docs/local/integrations/docusaurus",
          },
          {
            text: "VitePress",
            link: "/docs/local/integrations/vitepress",
          },
          {
            text: "Astro",
            link: "/docs/local/integrations/astro",
          },
          {
            text: "Starlight",
            link: "/docs/local/integrations/starlight",
          },
          {
            text: "Nextra",
            link: "/docs/local/integrations/nextra",
          },
        ],
      },
    ],
  },
  {
    text: "Cloud",
    items: [
      {
        text: "Demo",
        link: "/docs/cloud/demo",
      },
      {
        text: "Introduction",
        link: "/docs/cloud/intro",
      },
      {
        text: "Integrations",
        collapsed: true,
        items: [
          {
            text: "Docusaurus",
            link: "/docs/cloud/integrations/docusaurus",
          },
          {
            text: "VitePress",
            link: "/docs/cloud/integrations/vitepress",
          },
          {
            text: "Astro",
            link: "/docs/cloud/integrations/astro",
          },
          {
            text: "Starlight",
            link: "/docs/cloud/integrations/starlight",
          },
          {
            text: "Nextra",
            link: "/docs/cloud/integrations/nextra",
          },
        ],
      },
    ],
  },
  {
    text: "Reference",
    collapsed: false,
    items: [
      {
        text: "Packages",
        link: "/docs/reference/packages",
      },
      {
        text: "Components",
        link: "/docs/reference/components",
      },
      {
        text: "Storybook",
        link: "https://storybook.getcanary.dev",
      },
    ],
  },
];

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Canary",
  description: "Canary",
  srcDir: "./contents",
  sitemap: { hostname: "https://getcanary.dev" },
  lastUpdated: true,
  markdown: {
    image: {
      lazyLoading: true,
    },
  },
  transformPageData(pageData) {
    const canonicalUrl = `https://getcanary.dev/${pageData.relativePath}`
      .replace(/index\.md$/, "")
      .replace(/\.md$/, ".html");

    pageData.frontmatter.head ??= [];
    pageData.frontmatter.head.push(
      ["link", { rel: "canonical", href: canonicalUrl }],
      [
        "meta",
        {
          name: "og:title",
          content:
            pageData.frontmatter.layout === "home"
              ? `Canary`
              : `${pageData.title} | Canary`,
        },
      ],
      [
        "meta",
        {
          name: "og:description",
          content:
            pageData.frontmatter.layout === "home"
              ? "Searchbar that your users love to use. Optimized for techincal docs with AI."
              : pageData.frontmatter.description,
        },
      ],
      [
        "meta",
        {
          name: "twitter:title",
          content:
            pageData.frontmatter.layout === "home"
              ? `Canary`
              : `${pageData.title} | Canary`,
        },
      ],
      [
        "meta",
        {
          name: "twitter:description",
          content:
            pageData.frontmatter.layout === "home"
              ? "Searchbar that your users love to use. Optimized for techincal docs with AI."
              : pageData.frontmatter.description,
        },
      ],
    );
  },
  vue: {
    template: {
      compilerOptions: {
        isCustomElement: (tag) => tag.includes("canary-"),
      },
    },
  },
  vite: {
    plugins: [unocss()],
    resolve: {
      alias: [
        {
          find: /^.*\/VPNavBarSearch\.vue$/,
          replacement: fileURLToPath(
            new URL("../components/Empty.vue", import.meta.url),
          ),
        },
      ],
    },
    ssr: {
      noExternal: ["@nolebase/vitepress-plugin-highlight-targeted-heading"],
    },
  },
  themeConfig: {
    search: { provider: "local" },
    // https://vitepress.dev/reference/default-theme-config
    siteTitle: "Canary",
    logo: { src: '/getcanary-logo.svg', width: 24, height: 24 },
    nav: [
      { text: "Blog", link: "/blog" },
      {
        text: "⭐ GitHub",
        link: "https://github.com/fastrepl/canary",
      },
      {
        text: "Discord",
        link: "https://discord.gg/Y8bJkzuQZU",
      },
    ],
    sidebar: {
      "/": sidebar,
      "/docs/": sidebar,
    },
    outline: { level: [2, 3] },
    editLink: {
      pattern:
        "https://github.com/fastrepl/canary/edit/main/js/apps/docs/contents/:path",
    },
  },
});
