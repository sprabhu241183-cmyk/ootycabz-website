(function () {
  if ("serviceWorker" in navigator && location.protocol === "https:") {
    window.addEventListener("load", function () { navigator.serviceWorker.register("/sw.js").catch(function () {}); });
  }
  var installButton = document.getElementById("pwaInstall");
  var help = document.getElementById("pwaHelp");
  var close = document.getElementById("pwaHelpClose");
  if (!installButton || !help) return;
  var deferredPrompt = null;
  var isStandalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true;
  if (isStandalone) return;
  installButton.hidden = false;
  window.addEventListener("beforeinstallprompt", function (event) {
    event.preventDefault();
    deferredPrompt = event;
    installButton.textContent = "＋ Install Ooty Cabz";
  });
  installButton.addEventListener("click", async function () {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      try { await deferredPrompt.userChoice; } catch (e) {}
      deferredPrompt = null;
      installButton.hidden = true;
      return;
    }
    var ua = navigator.userAgent || "";
    var isIOS = /iphone|ipad|ipod/i.test(ua);
    help.hidden = false;
    help.querySelector("[data-install-steps]").textContent = isIOS
      ? "On your iPhone: tap the Share button in Safari, then choose “Add to Home Screen”."
      : "Open your browser menu (⋮) and choose “Install app” or “Add to Home screen”.";
  });
  if (close) close.addEventListener("click", function () { help.hidden = true; });
  window.addEventListener("appinstalled", function () { installButton.hidden = true; });
})();