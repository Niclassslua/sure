import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="fints"
export default class extends Controller {
  static values = {
    baseUrl: String,
    accountId: String,
  };

  static targets = ["days", "pin", "status", "confirmButton"];

  start() {
    const days = parseInt(this.daysTarget.value || "30", 10);
    const headers = { "Content-Type": "application/json" };
    if (this.pinTarget.value) {
      headers["x-pin"] = this.pinTarget.value;
    }
    this.updateStatus("Starting session...");
    fetch(`${this.baseUrlValue}/sessions`, {
      method: "POST",
      headers: headers,
      body: JSON.stringify({ days: days }),
    })
      .then((r) => r.json())
      .then((data) => {
        this.sessionId = data.session_id;
        this.poll();
      })
      .catch((e) => this.updateStatus(`Error: ${e}`));
  }

  poll() {
    fetch(`${this.baseUrlValue}/sessions/${this.sessionId}`)
      .then((r) => r.json())
      .then((data) => {
        switch (data.status) {
          case "pending":
          case "processing":
            this.updateStatus(data.status);
            setTimeout(() => this.poll(), 2000);
            break;
          case "need_confirmation":
            this.updateStatus(data.challenge || data.hint || "Confirmation required");
            this.confirmButtonTarget.classList.remove("hidden");
            break;
          case "done":
            this.updateStatus("Downloading...");
            this.downloadResult();
            break;
          case "error":
            this.updateStatus(data.error || "Error");
            break;
        }
      })
      .catch((e) => this.updateStatus(`Error: ${e}`));
  }

  confirm() {
    this.confirmButtonTarget.classList.add("hidden");
    fetch(`${this.baseUrlValue}/sessions/${this.sessionId}`, { method: "POST" })
      .then(() => {
        this.updateStatus("Processing...");
        setTimeout(() => this.poll(), 2000);
      })
      .catch((e) => this.updateStatus(`Error: ${e}`));
  }

  downloadResult() {
    fetch(`${this.baseUrlValue}/sessions/${this.sessionId}/result`)
      .then((r) => r.text())
      .then((csv) => {
        this.updateStatus("Importing...");
        return fetch(`/accounts/${this.accountIdValue}/import_fints`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          },
          body: JSON.stringify({ csv: csv }),
        });
      })
      .then((r) => r.json())
      .then((data) => {
        this.updateStatus(`Imported ${data.added} transactions`);
      })
      .catch((e) => this.updateStatus(`Error: ${e}`));
  }

  updateStatus(text) {
    this.statusTarget.textContent = text;
  }
}
