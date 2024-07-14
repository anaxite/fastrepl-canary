import { LitElement, css, html } from "lit";
import { customElement, property } from "lit/decorators.js";
import { classMap } from "lit/directives/class-map.js";

@customElement("canary-radio")
export class CanaryRadio extends LitElement {
  @property({
    type: Array,
    reflect: true,
    converter: {
      fromAttribute: (v, _) => String(v).split(","),
      toAttribute: (v, _) => (Array.isArray(v) ? v.join(",") : v),
    },
  })
  options: string[] = [];
  @property({ type: String, reflect: true }) selected = this.options[0];

  render() {
    return html`
      <div class="tabs">
        ${this.options.map(
          (option, index) =>
            html`<div
              class=${classMap({
                tab: true,
                selected: option === this.selected,
                left: index === 0,
                right: index === this.options.length - 1,
              })}
              @click=${() => this._handleClick(option)}
            >
              <input
                type="radio"
                name="mode"
                .id=${option}
                .value=${option}
                ?checked=${option === this.selected}
              />
              <label>${option}</label>
            </div>`,
        )}
      </div>
    `;
  }

  private _handleClick(option: string) {
    this.selected = option;
    const event = new Event("change", { bubbles: true, composed: true });
    this.dispatchEvent(event);
  }

  static styles = [
    css`
      .tabs {
        display: flex;
        flex-direction: row;
      }

      .tab {
        cursor: pointer;
        font-family: var(--canary-font-family);
        font-size: 12px;

        padding: 4px 8px;
        font-size: 12px;
        border: 1px solid var(--canary-color-gray-4);

        color: var(--canary-color-gray-1);
        background-color: var(--canary-color-gray-6);
      }

      .tab:hover,
      .selected {
        color: var(--canary-color-gray-6);
        background-color: var(--canary-color-gray-1);
      }

      input {
        display: none;
      }

      .left {
        border-radius: 8px 0 0 8px;
        border-right: none;
      }

      .right {
        border-radius: 0 8px 8px 0;
        border-left: none;
      }
    `,
  ];
}
