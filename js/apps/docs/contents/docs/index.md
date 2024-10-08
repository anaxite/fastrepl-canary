<script setup>
import SizeChart from '../../components/SizeChart.vue'
import Chat from '../../components/Chat.vue'
import Headline from '../../components/Headline.vue'
import KeywordSearchProblem from '../../components/KeywordSearchProblem.vue'
import KeywordSearchSolution from '../../components/KeywordSearchSolution.vue'
import SearchDigestProblem from '../../components/SearchDigestProblem.vue'
import SearchDigestSolution from '../../components/SearchDigestSolution.vue'
import QueryRankChart from '../../components/QueryRankChart.vue'

import { data as canarySearch } from '../../data/size_canary_search.data.js'
import { data as canaryAll } from '../../data/size_canary_all.data.js'
import { data as docsearch } from '../../data/size_docsearch.data.js'
import { data as inkeep } from '../../data/size_inkeep.data.js'
import { data as kapa } from '../../data/size_kapa.data.js'
import { data as mendable } from '../../data/size_mendable.data.js'

const packages = {
  "@docsearch/js": docsearch.size,
  '🐤@getcanary/web (Search)': canarySearch.size,
  '🐤@getcanary/web (Search + Ask)': canaryAll.size,
  "kapa-widget.bundle.js": kapa.size,
  "@mendable/search": mendable.size,
  "@inkeep/uikit-js": inkeep.size,
}

const keywordSearchProblemExample = {
  left: {
    query: "how to limit api cost",
    items: [
      {
        title: "Router - Load Balancing, Fallbacks",
        excerpt: "...litellm_model_<mark>cost</mark>_map -> use deployment_<mark>cost</mark>..."
      }
    ],
    emoji: "😢"
  },
  right: {
    query: "budget",
    items: [
      {
        title: "Budgets, Rate Limits",
        excerpt: "Set <mark>Budget</mark>s"
      },
      {
        title: "Budgets, Rate Limits",
        excerpt: "Setting Team <mark>Budget</mark>s"
      }
    ],
    emoji: "😊"
  }
}

const searchDigestProblemExample = {
  query: "config feature_a",
  items: [
    {
      excerpt: "<mark>feature_a</mark>: option_1, option_2, option_3, option_4, option_5...",
      title: "Reference - <mark>config</mark>.yaml"
    },
    {
      excerpt: "...<mark>feature_a</mark>is really good. there's 999 ways of doing...",
      title: "What is <mark>Feature_A</mark>?"
    },
    {
      excerpt: "...to configure options for <mark>feature_a</mark>, you shoud do this and that...",
      title: "Tutorial - <mark>Config</mark>uration"
    }
  ]
}
</script>

<Headline />

Canary is an open-source project to help you implement a beautiful, functional search experience on your documentation site. 

At its core, Canary offers a set of UI components that you can implement on a documentation site. Connect these components to one of multiple search providers, whether local, in the cloud, or AI-based.

## Benefits

### Multiple integrations

Canary currently supports [Docusaurus](https://docusaurus.io/), [VitePress](https://vitepress.dev/), and [Starlight](https://starlight.astro.build/) documentation site generators. Its components also integrate with other frameworks.

Canary offers [`local`](/docs/local/intro) and [`cloud`](/docs/cloud/intro) search options.
Use local search to quickly add search functionality to your docs, without the need for any accounts.

You can also migrate to Canary Cloud later for extra features.

```html-vue
<canary-root framework="docusaurus">
  <canary-provider-pagefind> // [!code --]
  <canary-provider-cloud api-key="KEY" api-base="https://cloud.getcanary.dev"> // [!code ++]
    <!-- Rest of the code -->
  </canary-provider-cloud> // [!code ++]
  </canary-provider-pagefind> // [!code --]
</canary-root>
```

### Lightweight, versatile components

Canary components are [web components](https://developer.mozilla.org/en-US/docs/Web/Web_Components), easy for browsers to render.

<sub><a href="https://github.com/fastrepl/canary/tree/main/js/apps/docs/data">source</a></sub>

<SizeChart 
title="Bundle size (Uncompressed)"
:labels="Object.keys(packages)"
:values="Object.values(packages)"
/>

### Modular and open-source

We have put a lot of effort into making the core parts of the project as modular as possible, and we welcome contributions! [Find and ⭐️ us on GitHub](https://github.com/fastrepl/canary).

## Use cases

### Improving keyword-based search results 

A typical search experience looks like this:

<KeywordSearchProblem v-bind="keywordSearchProblemExample" />

It can lead to support questions like this one:

<Chat
  left="👤 hi there! how can i <strong>set limit for api cost?</strong>"
  right="Here is <strong>our documentation</strong> for that. (readthemanual.com/<strong>budget</strong>-and-rate-limits) 👤"
/>

With Canary, keywords are inferred.

::: warning Example ↓

<KeywordSearchSolution />

:::

### Making search results easy to understand

As your documentation grows, users often need to spend more time finding answers to their questions.

<SearchDigestProblem v-bind="searchDigestProblemExample" />

With Canary, their questions are "answered" with references.

::: warning Example ↓

<SearchDigestSolution />

:::
