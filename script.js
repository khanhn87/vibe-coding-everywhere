const buttons = document.querySelectorAll("button[data-copy]");

for (const button of buttons) {
  button.addEventListener("click", async () => {
    const targetId = button.getAttribute("data-copy");
    const codeEl = document.getElementById(targetId);
    if (!codeEl) return;

    try {
      await navigator.clipboard.writeText(codeEl.innerText);
      const original = button.textContent;
      button.textContent = "Copied";
      setTimeout(() => {
        button.textContent = original;
      }, 1000);
    } catch {
      button.textContent = "Copy failed";
      setTimeout(() => {
        button.textContent = "Copy";
      }, 1000);
    }
  });
}
