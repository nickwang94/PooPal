// Apply the saved appearance before first paint so there is no light flash in dark mode.
;(function () {
  var pref = 'system'
  try {
    pref = localStorage.getItem('poopal.appearance') || 'system'
  } catch (e) {
    // Storage blocked: follow the system.
  }
  var dark = pref === 'dark' || (pref === 'system' && matchMedia('(prefers-color-scheme: dark)').matches)
  document.documentElement.dataset.theme = dark ? 'dark' : 'light'
})()
