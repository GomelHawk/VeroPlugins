// What the plugin draws from, for this session only. Add your own fields below the
// three the source check needs; the engine checks every `$.state` write against this.
export type View = {
  // where this copy was installed from: `home` is VeroPlugins, `dev` a --plugin-dir or
  // test copy, `foreign` any other marketplace - that copy is stopped
  source: { kind: 'home' } | { kind: 'dev' } | { kind: 'foreign'; marketplace: string }
  // an older copy of this plugin still enabled under another marketplace; a home copy
  // beside one is stopped until it is removed
  legacy?: { marketplace: string; scope: 'user' | 'project' | 'local' }
  // the move command waiting for "Replace your draft?" to be answered
  confirmingFill?: string
}

declare module 'claude-code' {
  interface PluginState {
    'vero-x': { view: View }
  }
}
