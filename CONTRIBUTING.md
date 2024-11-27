# How to contribute

Contributions are welcome, especially for the `@getcanary/web` package and the docs. Follow the instructions in this document to get started.

## Quick start

1. Fork this repository
2. Create a new local branch
3. Submit a merge request upstream from your local branch.

## Set up dev environments

### @getcanary/web

`@getcanary/web` files are in js/packages/web.

Install dependencies with npm, and use Storybook for development.

```bash
cd <git_repo>/js/packages/web
npm install
npm run storybook
```

### Documentation

The @getcanary documentation platform is based on VitePress. Documentation files are in js/apps/docs, but you first need to install the dependencies for `@getcanary/web` to build properly.

1. Install `@getcanary/web` dependencies.
2. Install docs dependencies with npm.
3. Run a first build to enable dev previews.

```bash
cd <git_repo>/js/apps/docs
npm install
npm run build
npm run dev
```
