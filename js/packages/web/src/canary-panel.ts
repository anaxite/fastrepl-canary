import { LitElement, css, html, nothing } from "lit";
import { customElement, property, state } from "lit/decorators.js";
import { Task } from "@lit/task";

import "./canary-radio";
import "./canary-input";
import "./canary-reference";
import "./canary-reference-skeleton";
import "./canary-footer";
import "./canary-loading-dots";
import "./canary-error";
import "./canary-markdown";
import "./canary-search-results";

import { randomInteger } from "./utils";

import { type Reference, ask, search } from "./core";

@customElement("canary-panel")
export class CanaryPanel extends LitElement {
  @property() key = "";
  @property() endpoint = "";
  @property() hljs = "github-dark";

  @property() mode = "Search";
  @property({ reflect: true }) query = "";

  @state() askReferences: Reference[] = [];
  @state() askLoading = false;
  @state() response = "";

  @state() searchReferences: Reference[] = [];

  private _task = new Task(this, {
    task: async ([mode, query], { signal }) => {
      if (query === "") {
        return [];
      }

      if (mode === "Search") {
        const result = await search(
          this.key,
          this.endpoint,
          this.query,
          signal,
        );

        this.searchReferences = result;
        return this.searchReferences;
      }

      if (mode === "Ask") {
        this.askLoading = true;
        this.response = "";

        await ask(
          this.key,
          this.endpoint,
          randomInteger(),
          this.query,
          (delta) => {
            this.askLoading = false;

            if (delta.type === "progress") {
              this.response += delta.content;
            }
            if (delta.type === "references") {
              this.askReferences = delta.items;
            }
          },
          signal,
        );

        return this.askReferences;
      }
    },
    args: () => [this.mode, this.query],
  });

  render() {
    return html`
      <div class="container">
        <div class="input-wrapper">
          ${this.mode === "Search"
            ? html`
                <canary-input-search
                  value=${this.query}
                  @change=${this._handleChange}
                  @toggle=${this._handleToggle}
                >
                </canary-input-search>
              `
            : html`
                <canary-input-ask
                  value=${this.query}
                  @change=${this._handleChange}
                  @toggle=${this._handleToggle}
                >
                </canary-input-ask>
              `}

          <slot name="radio">
            <canary-radio
              .options=${["Search", "Ask"]}
              selected=${this.mode}
              @change=${this._handleToggle}
            ></canary-radio>
          </slot>
        </div>

        ${this.mode === "Search"
          ? html`<div class="callouts"><slot name="callout"></slot></div>`
          : nothing}
        <div class="results">${this.results()}</div>

        <canary-footer></canary-footer>
      </div>
    `;
  }

  results() {
    return html`
      ${this._task.render({
        initial: () => nothing,
        pending: () =>
          this.mode === "Search"
            ? html` <div class="skeleton-container">
                ${Array(4).fill(
                  html`<canary-reference-skeleton></canary-reference-skeleton>`,
                )}
              </div>`
            : html`
                <div class="ai-message">
                  ${
                    this.askLoading
                      ? html`<canary-loading-dots></canary-loading-dots>`
                      : html`<canary-markdown
                          hljs=${this.hljs}
                          .content=${this.response}
                        ></canary-markdown>`
                  }

             <div class="references">
                          ${this.askReferences.map(
                            (item) =>
                              html` <canary-reference
                                title=${item.title}
                                url=${item.url}
                              ></canary-reference>`,
                          )}
                        </div>
                      </div>
                  </div>
                </div>
              `,
        complete:
          this.mode === "Search"
            ? (items) =>
                html`<canary-search-results
                  .items=${items ?? []}
                ></canary-search-results>`
            : (items) =>
                this.query === ""
                  ? nothing
                  : html`
                      <div class="ai-message">
                        <canary-markdown
                          hljs=${this.hljs}
                          .content=${this.response}
                        ></canary-markdown>
                        <div class="references">
                          ${(items ?? []).map(
                            (item) =>
                              html` <canary-reference
                                title=${item.title}
                                url=${item.url}
                              ></canary-reference>`,
                          )}
                        </div>
                      </div>
                    `,
        error: (error) => {
          console.error(error);
          return html` <canary-error></canary-error>`;
        },
      })}
    `;
  }

  private _handleChange(e: CustomEvent) {
    this.query = e.detail;
  }

  private _handleToggle(e: CustomEvent) {
    if (this.mode === "Ask") {
      this.query = "";
    }

    this.mode = e.detail;
  }

  static styles = [
    css`
      div.container {
        max-width: 500px;
        padding: 8px 8px;
        border: none;
        border-radius: 8px;
        outline: none;
        color: var(--canary-color-gray-1);
        background-color: var(--canary-color-black);
        box-shadow:
          0 20px 25px -5px rgb(0 0 0 / 0.1),
          0 8px 10px -6px rgb(0 0 0 / 0.1);
      }

      div.input-wrapper {
        display: flex;
        align-items: center;
        gap: 8px;
        margin-bottom: 4px;
        padding: 1px 6px;
      }
    `,
    css`
      .ai-message {
        border: 1px solid var(--canary-color-gray-6);
        border-radius: 8px;
        padding: 0px 12px;
      }
    `,
    css`
      div.references {
        display: flex;
        flex-direction: column;
        gap: 6px;
        padding-bottom: 8px;
      }

      div.callouts {
        display: flex;
        flex-direction: column;
      }
    `,
    css`
      .skeleton-container {
        display: flex;
        flex-direction: column;
        gap: 8px;
        height: 350px;
      }
    `,
    css`
      .logo {
        padding-top: 8px;
        text-align: end;
        font-size: 12px;
        color: var(--canary-color-gray-2);
      }

      .logo a {
        text-decoration: none;
        color: var(--canary-color-gray-1);
      }
      .logo a:hover {
        text-decoration: underline;
        color: var(--canary-color-white);
      }
    `,
  ];
}
