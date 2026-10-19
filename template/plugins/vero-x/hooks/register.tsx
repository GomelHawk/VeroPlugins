import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { View } from '../types'
import {
  MOVE_LABELS,
  REMOVE_LABEL,
  REPLACE_NO,
  REPLACE_QUESTION,
  REPLACE_YES,
  RESTART_NOTE,
  fillRefusedToast,
  legacyBand,
  legacyCopies,
  legacyMarkdown,
  legacyToast,
  moveSteps,
  removeStep,
  sourceOf,
  stoppedBand,
  stoppedMarkdown,
  stoppedToast,
} from './source-check'
import type { LegacyCopy, ScopeSettings, Source } from './source-check'

// VeroX - SLOGAN_X
// ONE_LINE_X
//
// This module is the part every Vero plugin shares: the source check and its stopped
// mode, the command, the band above the prompt. Add your hooks below "the plugin's own
// hooks"; every one of them starts with `if (isStopped(v)) return next(e)`.

const PLUGIN = 'vero-x'
const DISPLAY = 'VeroX'
// What the move leaves in place, for the stopped message: a phrase such as
// "VeroX's cache lives in ~/.cache/vero-x". `undefined` when the plugin keeps nothing.
const KEEPS: string | undefined = undefined

const TOAST = {
  error: 'VeroX could not do that.',
}

const INITIAL: View = { source: { kind: 'dev' } }
const view = atom({ plugin: 'vero-x', key: 'view' } as const, INITIAL)

// A new session or turn starts from nothing, except where this copy came from: that is
// re-read, never forgotten.
const reset = ($: EngineInterface) => update($, view, cur => ({ ...INITIAL, source: cur.source, legacy: cur.legacy }))

// --- the source check -------------------------------------------------------------------
// VeroX works only when installed from VeroPlugins (the `vero-plugins` marketplace) or
// loaded as a development copy. A copy from any other marketplace is stopped: every hook
// passes through, and the band above the prompt holds the commands that move it. A home
// copy beside an older copy of itself (enabled in the settings under another marketplace)
// stops too, so two copies never act together.

async function checkSource($: EngineInterface): Promise<{ source: Source; legacy?: LegacyCopy }> {
  try {
    let source = sourceOf($.plugin.root)
    if (source.kind === 'dev') {
      // the test seam: only a development copy consults it, so no installed copy can opt out
      const testRoot = await $.env.get('VERO_TEST_ROOT')
      if (testRoot) source = sourceOf(testRoot)
    }
    if (source.kind !== 'home') return { source }
    const sources: ScopeSettings[] = []
    for (const scope of ['user', 'project', 'local'] as const) {
      sources.push({ scope, settings: await $.settings.read({ source: scope }).catch(() => undefined) })
    }
    return { source, legacy: legacyCopies(PLUGIN, sources)[0] }
  } catch {
    return { source: { kind: 'dev' } }
  }
}

const isStopped = (v: View) => v.source.kind === 'foreign' || v.legacy !== undefined

// While a copy works, its source is re-read at most this often: another copy appearing
// beside it mid-session is rare, and the band tells the person to restart anyway. A
// stopped copy re-reads on every turn, so the old copy's removal is seen at the next Enter.
const RECHECK_MS = 10_000
let checkedAt = -Infinity

async function refreshSource($: EngineInterface, isForced: boolean): Promise<{ source: Source; legacy?: LegacyCopy }> {
  const v = await read($, view)
  const now = await $.clock.now()
  if (!isForced && !isStopped(v) && now - checkedAt < RECHECK_MS) return { source: v.source, legacy: v.legacy }
  checkedAt = now
  return checkSource($)
}

// The stopped message: the command's answer.
function stoppedMessage(v: View): string {
  if (v.legacy !== undefined) return legacyMarkdown(DISPLAY, PLUGIN, v.legacy)
  return stoppedMarkdown(DISPLAY, PLUGIN, v.source.kind === 'foreign' ? v.source.marketplace : '', KEEPS)
}

// Puts one move command into the prompt box, for the person to press Enter on. A draft
// already there is never overwritten without asking.
async function fillCommand($: EngineInterface, command: string, isConfirmed = false) {
  if (!isConfirmed) {
    const { text } = await $.prompt.read()
    if (text.trim() !== '' && text !== command) {
      await update($, view, cur => ({ ...cur, confirmingFill: command }))
      return
    }
  }
  await update($, view, cur => ({ ...cur, confirmingFill: undefined }))
  const filled = await $.prompt.fill({ text: command, mode: 'replace' })
  if (!filled.isFilled) $.ui.toast(fillRefusedToast(DISPLAY))
}

// Every press runs through here, so a failure is a toast rather than an unhandled
// rejection.
const pressed = ($: EngineInterface, work: () => Promise<unknown>) => () => {
  void work().catch(() => $.ui.toast(TOAST.error))
}

// What `/vero-x` answers while the plugin works: the name, the slogan, what it does.
// Extend it with the plugin's state and its options' values.
function statusText(): string {
  return ['**VeroX** - *SLOGAN_X*', '', 'ONE_LINE_X'].join('\n')
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const { source, legacy } = await refreshSource($, true)
    await update($, view, () => ({ ...INITIAL, source, legacy }))
    await $.command.register({
      name: 'vero-x',
      description: 'VeroX: what it does',
    })
    // stopped: the command answers, the band says how to move; nothing else happens
    if (legacy !== undefined) $.ui.toast(legacyToast(DISPLAY, legacy), { timeoutMs: 8000 })
    else if (source.kind === 'foreign') $.ui.toast(stoppedToast(DISPLAY, source.marketplace), { timeoutMs: 8000 })
    return next(e)
  })

  // A /clear ends the conversation with no session.start after it.
  on('session.end', async ($, e, next) => {
    const done = await next(e)
    await reset($)
    return done
  })

  // The source is read again each turn: an install or uninstall mid-session is picked up
  // here (every turn while stopped, at most every 10 s while working).
  on('turn.start', async ($, e, next) => {
    const { source, legacy } = await refreshSource($, false)
    await update($, view, () => ({ ...INITIAL, source, legacy }))
    return next(e)
  })

  on('command.run', { command: 'vero-x' }, async ($) => {
    const v = await read($, view)
    return { text: isStopped(v) ? stoppedMessage(v) : statusText() }
  })

  // The band above the prompt: nothing, unless this copy is stopped. Then the reason and
  // the buttons that put the move commands into the prompt box, with what the plugins
  // beneath drew kept under it. No ×: the row stays until the copy is moved.
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const v = await read($, view)
    if (e.props.hasSurvey || !isStopped(v)) return next(e)
    const { Box, Text, Button } = $.ui.resolve(e)
    const below = await next(e)
    const legacy = v.legacy
    const marketplace = v.source.kind === 'foreign' ? v.source.marketplace : ''
    const fill = (command: string, isConfirmed = false) => pressed($, () => fillCommand($, command, isConfirmed))

    const buttons =
      v.confirmingFill !== undefined ? (
        <Box flexDirection="row" gap={1}>
          <Text>{REPLACE_QUESTION}</Text>
          <Button key="vero-x-move:replace" variant="primary" onPress={fill(v.confirmingFill, true)}>
            {REPLACE_YES}
          </Button>
          <Button key="vero-x-move:cancel" onPress={pressed($, () => update($, view, cur => ({ ...cur, confirmingFill: undefined })))}>
            {REPLACE_NO}
          </Button>
        </Box>
      ) : legacy !== undefined ? (
        <Box flexDirection="row" gap={2}>
          <Button key="vero-x-move:remove" onPress={fill(removeStep(PLUGIN, legacy))}>
            {REMOVE_LABEL}
          </Button>
          <Text dimColor>{RESTART_NOTE}</Text>
        </Box>
      ) : (
        <Box flexDirection="row" gap={2}>
          {moveSteps(PLUGIN, marketplace).map((command, i) => (
            <Button key={`vero-x-move:${i + 1}`} onPress={fill(command)}>
              {MOVE_LABELS[i]}
            </Button>
          ))}
          <Text dimColor>{RESTART_NOTE}</Text>
        </Box>
      )

    return (
      <Box flexDirection="column">
        <Text>{legacy !== undefined ? legacyBand(DISPLAY, legacy) : stoppedBand(DISPLAY, marketplace)}</Text>
        {buttons}
        {below}
      </Box>
    )
  })

  // --- the plugin's own hooks ----------------------------------------------------------
  // Add them here. Every one starts with the stopped check, so a copy from anywhere but
  // VeroPlugins does nothing at all:
  //
  //   on('turn.complete', async ($, e, next) => {
  //     const v = await read($, view)
  //     if (isStopped(v)) return next(e)
  //     ...
  //     return next(e)
  //   })
  //
  // A hook that gates something (ui.close, tool.call, a render that replaces the engine's
  // drawing) ends with `.catch(($, e, next) => next(e))`, so a failure is never worse than
  // no plugin.
}
