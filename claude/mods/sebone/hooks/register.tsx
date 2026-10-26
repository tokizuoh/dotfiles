import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Quote } from '../types'

const current = atom({ plugin: 'sebone', key: 'current' } as const, null)

const isQuote = (v: unknown): v is Quote =>
  typeof v === 'object' && v !== null && typeof (v as Quote).text === 'string'

// mod は ~/.claude/skills/sebone へのシンボリックリンク経由で読み込まれるので、
// 実体（dotfiles/claude/mods/sebone）まで解決してから2つ上の claude/quotes.json を指す。
// ホームや ghq の置き場所は PC ごとに違うため、絶対パスで持たない
const quotesPath = async ($: EngineInterface): Promise<string> => {
  const stat = await $.fs.stat($.plugin.root, { resolve: true }).catch(() => undefined)
  const root = stat?.realPath ?? $.plugin.root
  return `${root.replace(/\/+$/, '').split('/').slice(0, -2).join('/')}/quotes.json`
}

const loadQuotes = async ($: EngineInterface): Promise<Quote[]> => {
  try {
    const parsed: unknown = JSON.parse((await $.fs.read(await quotesPath($))) as string)
    return Array.isArray(parsed) ? parsed.filter(isQuote) : []
  } catch {
    return []
  }
}

// 名言を足したらすぐ反映されるよう、毎回ファイルを読み直す
const pick = async ($: EngineInterface) => {
  const quotes = await loadQuotes($)
  const prev = await read($, current)
  const candidates =
    quotes.length > 1 ? quotes.filter(q => q.text !== prev?.text) : quotes
  const next = candidates[Math.floor(Math.random() * candidates.length)] ?? null
  await update($, current, () => next)
}

export const register: Register = on => {
  // 名言の選び直しに失敗しても、セッション開始やプロンプト送信は止めない
  on('session.start', async ($, e, next) => {
    await pick($).catch(() => {})
    return next(e)
  })

  // 時間切れでも送信を止めないよう、登録側の catch でも素通しにする
  on('prompt.submit', async ($, e, next) => {
    await pick($).catch(() => {})
    return next(e)
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const quote = await read($, current)
    if (e.props.hasSurvey || quote === null) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box>
        <Text dimColor>🗿 {quote.text}</Text>
      </Box>
    )
  })
}
