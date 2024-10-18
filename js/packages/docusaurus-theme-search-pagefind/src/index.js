import fs from "fs";
import path from "path";

import { getFilePaths, getVersions } from "./utils";
import { buildIndex } from "./pagefind";

/**
 * @typedef {import("@docusaurus/types").Plugin} Plugin
 * @typedef {import("@docusaurus/types").DocusaurusContext} DocusaurusContext
 * @typedef {import("webpack").Configuration} WebpackConfiguration
 * @param {DocusaurusContext} context
 */
export default function plugin(context, options) {
  const { indexOnly = false } = options;

  /**
   * @type {Plugin}
   */
  const config = {
    name: "docusaurus-theme-search-pagefind",
    async contentLoaded({ actions }) {
      actions.setGlobalData({ options });
    },
    async postBuild({ siteDir, routesPaths = [], outDir, baseUrl }) {
      const versions = getVersions(siteDir);
      if (!versions && !options.tags) {
        console.warn("'Versions' detected, and 'tags' is not configured.");
      }

      const docs = getFilePaths(routesPaths, outDir, baseUrl, options);
      await buildIndex(outDir, docs, options);
    },
    /**
     * @returns {WebpackConfiguration}
     */
    configureWebpack(config, isServer, utils) {
      return {
        devServer: {
          setupMiddlewares(middlewares, devServer) {
            devServer.app.get("/pagefind/*", (req, res) => {
              const filePath = path.join(context.outDir, req.path);

              if (fs.existsSync(filePath)) {
                res.sendFile(filePath);
              } else {
                res.status(404).send("");
              }
            });

            return middlewares;
          },
        },
      };
    },
  };

  if (indexOnly) {
    return config;
  }

  return {
    ...config,
    getThemePath() {
      return path.resolve(__dirname, "./theme");
    },
  };
}
