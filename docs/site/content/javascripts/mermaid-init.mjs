// Mermaid diagram initialization with AduaNext brand colors
document.addEventListener("DOMContentLoaded", () => {
  if (typeof mermaid !== "undefined") {
    mermaid.initialize({
      startOnLoad: true,
      theme: "base",
      themeVariables: {
        primaryColor: "#1E3A5F",
        primaryTextColor: "#fff",
        primaryBorderColor: "#0F1D30",
        lineColor: "#64748B",
        secondaryColor: "#D97706",
        tertiaryColor: "#0EA5E9",
        fontFamily: "Inter, sans-serif",
      },
    });
  }
});
